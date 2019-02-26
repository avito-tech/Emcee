import EventBus
import Foundation
import SimulatorPool
import Models
import fbxctest
import LocalHostDeterminer
import Logging
import ProcessController
import TempFolder
import ResourceLocationResolver

/// This class runs the given tests on a single simulator.
public final class Runner {
    private let eventBus: EventBus
    private let configuration: RunnerConfiguration
    private let tempFolder: TempFolder
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        eventBus: EventBus,
        configuration: RunnerConfiguration,
        tempFolder: TempFolder,
        resourceLocationResolver: ResourceLocationResolver)
    {
        self.eventBus = eventBus
        self.configuration = configuration
        self.tempFolder = tempFolder
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    /** Runs the given tests, attempting to restart the runner in case of crash. */
    public func run(entries: [TestEntry], onSimulator simulator: Simulator) throws -> [TestEntryResult] {
        if entries.isEmpty { return [] }
        
        let runResult = RunResult()
        
        // To not retry forever.
        // It is unlikely that multiple revives would provide any results, so we leave only a single retry.
        let numberOfAttemptsToRevive = 1
        
        // Something may crash (fbxctest/xctest), many tests may be not started. Some external code that uses Runner
        // may have its own logic for restarting particular tests, but here at Runner we deal with crashes of bunches
        // of tests, many of which can be even not started. Simplifying this: if something that runs tests is crashed,
        // we should retry running tests more than if some test fails. External code will treat failed tests as it
        // is promblem in them, not in infrastructure.
        
        var reviveAttempt = 0
        while runResult.nonLostTestEntryResults.count < entries.count, reviveAttempt <= numberOfAttemptsToRevive {
            let entriesToRun = missingEntriesForScheduledEntries(
                expectedEntriesToRun: entries,
                collectedResults: runResult)
            let runResults = try runOnce(entriesToRun: entriesToRun, onSimulator: simulator)
            runResult.append(testEntryResults: runResults)
            
            if runResults.filter({ !$0.isLost }).isEmpty {
                // Here, if we do not receive events at all, we will get 0 results. We try to revive a limited number of times.
                reviveAttempt += 1
                Logger.warning("Got no results. Attempting to revive #\(reviveAttempt) out of allowed \(numberOfAttemptsToRevive) attempts to revive")
            } else {
                // Here, we actually got events, so we could reset revive attempts.
                reviveAttempt = 0
            }
        }
        
        return testEntryResults(runResult: runResult)
    }
    
    /** Runs the given tests once without any attempts to restart the failed/crashed tests. */
    public func runOnce(entriesToRun: [TestEntry], onSimulator simulator: Simulator) throws -> [TestEntryResult] {
        if entriesToRun.isEmpty {
            Logger.info("Nothing to run!")
            return []
        }
        
        Logger.info("Will run \(entriesToRun.count) tests on simulator \(simulator)")
        
        let testContext = createTestContext(simulator: simulator)
        
        eventBus.post(event: .runnerEvent(.willRun(testEntries: entriesToRun, testContext: testContext)))
        
        let fbxctestOutputProcessor = try FbxctestOutputProcessor(
            subprocess: Subprocess(
                arguments: fbxctestArguments(entriesToRun: entriesToRun, simulator: simulator),
                environment: testContext.environment,
                maximumAllowedSilenceDuration: configuration.maximumAllowedSilenceDuration ?? 0
            ),
            simulatorId: simulator.identifier,
            singleTestMaximumDuration: configuration.singleTestMaximumDuration
        )
        fbxctestOutputProcessor.processOutputAndWaitForProcessTermination()
        
        let result = prepareResults(
            requestedEntriesToRun: entriesToRun,
            testEventPairs: fbxctestOutputProcessor.testEventPairs
        )
        
        eventBus.post(event: .runnerEvent(.didRun(results: result, testContext: testContext)))
        
        Logger.info("Attempted to run \(entriesToRun.count) tests on simulator \(simulator): \(entriesToRun)")
        Logger.info("Did get \(result.count) results: \(result)")
        
        return result
    }
    
    private func fbxctestArguments(entriesToRun: [TestEntry], simulator: Simulator) -> [SubprocessArgument] {
        let resolvableFbxctest = resourceLocationResolver.resolvable(withRepresentable: configuration.fbxctest)
        var arguments: [SubprocessArgument] =
            [resolvableFbxctest.asArgumentWith(packageName: PackageName.fbxctest),
             "-destination", simulator.testDestination.destinationString,
             configuration.testType.asArgument]
        
        let buildArtifacts = configuration.buildArtifacts
        let resolvableAppBundle = resourceLocationResolver.resolvable(withRepresentable: buildArtifacts.appBundle)
        let resolvableXcTestBundle = resourceLocationResolver.resolvable(withRepresentable: buildArtifacts.xcTestBundle)
        
        switch configuration.testType {
        case .logicTest:
            arguments += [resolvableXcTestBundle.asArgument()]
        case .appTest:
            arguments += [
                JoinedSubprocessArgument(
                    components: [resolvableXcTestBundle.asArgument(), resolvableAppBundle.asArgument()],
                    separator: ":")]
        case .uiTest:
            let resolvableRunnerBundle = resourceLocationResolver.resolvable(withRepresentable: buildArtifacts.runner)
            let resolvableAdditionalAppBundles = buildArtifacts.additionalApplicationBundles
                .map { resourceLocationResolver.resolvable(withRepresentable: $0) }
            let components = ([resolvableXcTestBundle, resolvableRunnerBundle, resolvableAppBundle] + resolvableAdditionalAppBundles)
                .map { $0.asArgument() }
            arguments += [JoinedSubprocessArgument(components: components, separator: ":")]
            
            if let simulatorLocatizationSettings = configuration.simulatorSettings.simulatorLocalizationSettings {
                arguments += [
                    "-simulator-localization-settings",
                    resourceLocationResolver.resolvable(withRepresentable: simulatorLocatizationSettings).asArgument()
                ]
            }
            if let watchdogSettings = configuration.simulatorSettings.watchdogSettings {
                arguments += [
                    "-watchdog-settings",
                    resourceLocationResolver.resolvable(withRepresentable: watchdogSettings).asArgument()
                ]
            }
        }
        
        arguments += entriesToRun.flatMap {
            ["-only", JoinedSubprocessArgument(components: [resolvableXcTestBundle.asArgument(), $0.testName], separator: ":")]
        }
        arguments += ["run-tests", "-sdk", "iphonesimulator"]
      
        if type(of: simulator) != Shimulator.self {
            arguments += ["-workingDirectory", simulator.workingDirectory.asString]
        }
        
        arguments += ["-keep-simulators-alive"]
        return arguments
    }
    
    private func createTestContext(simulator: Simulator) -> TestContext {
        var environment = configuration.environment
        do {
            let testsWorkingDirectory = try tempFolder.pathByCreatingDirectories(components: ["testsWorkingDir", UUID().uuidString])
            environment[RunnerConstants.envTestsWorkingDirectory.rawValue] = testsWorkingDirectory.asString
        } catch {
            Logger.error("Unable to create path tests working directory: \(error)")
        }
        return TestContext(environment: environment, testDestination: simulator.testDestination)
    }
    
    private func prepareResults(
        requestedEntriesToRun: [TestEntry],
        testEventPairs: [TestEventPair])
        -> [TestEntryResult]
    {
        return requestedEntriesToRun.map { requestedEntryToRun in
            prepareResult(
                requestedEntryToRun: requestedEntryToRun,
                testEventPairs: testEventPairs
            )
        }
    }
    
    private func prepareResult(
        requestedEntryToRun: TestEntry,
        testEventPairs: [TestEventPair])
        -> TestEntryResult
    {
        let correspondingEventPair = testEventPairForEntry(
            requestedEntryToRun,
            testEventPairs: testEventPairs)
        
        if let correspondingEventPair = correspondingEventPair, let finishEvent = correspondingEventPair.finishEvent {
            return testEntryResultForFinishedTest(
                testEntry: requestedEntryToRun,
                startEvent: correspondingEventPair.startEvent,
                finishEvent: finishEvent
            )
        } else {
            return .lost(testEntry: requestedEntryToRun)
        }
    }
    
    private func testEntryResultForFinishedTest(
        testEntry: TestEntry,
        startEvent: TestStartedEvent,
        finishEvent: TestFinishedEvent)
        -> TestEntryResult
    {
        return .withResult(
            testEntry: testEntry,
            testRunResult:
            TestRunResult(
                succeeded: finishEvent.succeeded,
                exceptions: finishEvent.exceptions.map { TestException(reason: $0.reason, filePathInProject: $0.filePathInProject, lineNumber: $0.lineNumber) },
                duration: finishEvent.totalDuration,
                startTime: startEvent.timestamp,
                finishTime: finishEvent.timestamp,
                hostName: startEvent.hostName ?? "host was not set to TestStartedEvent",
                processId: startEvent.processId ?? 0,
                simulatorId: startEvent.simulatorId ?? "unknown_simulator"
            )
        )
    }
    
    private func testEventPairForEntry(
        _ entry: TestEntry,
        testEventPairs: [TestEventPair])
        -> TestEventPair?
    {
        return testEventPairs.first(where: { $0.startEvent.testName == entry.testName })
    }
    
    private func missingEntriesForScheduledEntries(
        expectedEntriesToRun: [TestEntry],
        collectedResults: RunResult)
        -> [TestEntry]
    {
        let receivedTestEntries = Set(collectedResults.nonLostTestEntryResults.map { $0.testEntry })
        return expectedEntriesToRun.filter { !receivedTestEntries.contains($0) }
    }
    
    private func testEntryResults(runResult: RunResult) -> [TestEntryResult] {
        return runResult.testEntryResults.map {
            if $0.isLost {
                return resultForSingleTestThatDidNotRun(testEntry: $0.testEntry)
            } else {
                return $0
            }
        }
    }
    
    private func resultForSingleTestThatDidNotRun(testEntry: TestEntry) -> TestEntryResult {
        let timestamp = Date().timeIntervalSince1970
        return .withResult(
            testEntry: testEntry,
            testRunResult: TestRunResult(
                succeeded: false,
                exceptions: [
                    TestException(
                        reason: RunnerConstants.testDidNotRun.rawValue,
                        filePathInProject: #file,
                        lineNumber: #line
                    )
                ],
                duration: 0,
                startTime: timestamp,
                finishTime: timestamp,
                hostName: LocalHostDeterminer.currentHostAddress,
                processId: 0,
                simulatorId: "no_simulator"))
    }
}

private extension TestType {
    var asArgument: SubprocessArgument {
        return "-" + self.rawValue
    }
}
