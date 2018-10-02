import EventBus
import Foundation
import SimulatorPool
import Models
import fbxctest
import Logging
import HostDeterminer
import ProcessController

/// This class runs the given tests on a single simulator.
public final class Runner {
    private let eventBus: EventBus
    private let configuration: RunnerConfiguration
    
    public init(eventBus: EventBus, configuration: RunnerConfiguration) {
        self.eventBus = eventBus
        self.configuration = configuration
    }
    
    /** Runs the given tests, attempting to restart the runner in case of crash. */
    public func run(entries: [TestEntry], onSimulator simulator: Simulator) -> [TestRunResult] {
        if entries.isEmpty { return [] }
        
        var results = [TestRunResult]()
        
        // To not retry forever.
        // It is unlikely that multiple revives would provide any results, so we leave only a single retry.
        let numberOfAttemptsToRevive = 1
        
        // Something may crash (fbxctest/xctest), many tests may be not started. Some external code that uses Runner
        // may have its own logic for restarting particular tests, but here at Runner we deal with crashes of bunches
        // of tests, many of which can be even not started. Simplifying this: if something that runs tests is crashed,
        // we should retry running tests more than if some test fails. External code will treat failed tests as it
        // is promblem in them, not in infrastructure.
        
        var reviveAttempt = 0
        while results.count < entries.count, reviveAttempt <= numberOfAttemptsToRevive {
            let entriesToRun = missingEntriesForScheduledEntries(
                expectedEntriesToRun: entries,
                collectedResults: results)
            let runResults = runOnce(entriesToRun: entriesToRun, onSimulator: simulator)
            results.append(contentsOf: runResults)
            
            if runResults.isEmpty {
                // Here, if we do not receive events at all, we will get 0 results. We try to revive a limited number of times.
                reviveAttempt += 1
                log("Got no results. Attempting to revive #\(reviveAttempt) out of allowed \(numberOfAttemptsToRevive) attempts to revive")
            } else {
                // Here, we actually got events, so we could reset revive attempts.
                reviveAttempt = 0
            }
        }
        
        let resultsForTestsThatDidNotRun = self.resultsForTestsThatDidNotRun(
            testEntries: entries,
            resultsForFinishedTests: results)
        
        return results + resultsForTestsThatDidNotRun
    }
    
    /** Runs the given tests once without any attempts to restart the failed/crashed tests. */
    public func runOnce(entriesToRun: [TestEntry], onSimulator simulator: Simulator) -> [TestRunResult] {
        if entriesToRun.isEmpty {
            log("Nothing to run!", color: .blue)
            return []
        }
        
        log("Will run \(entriesToRun.count) tests on simulator \(simulator)", color: .blue)
        
        let testContext = self.testContext(simulator: simulator)
        
        eventBus.post(event: .runnerEvent(.willRun(testEntries: entriesToRun, testContext: testContext)))
        
        let fbxctestOutputProcessor = FbxctestOutputProcessor(
            subprocess: Subprocess(
                arguments: fbxctestArguments(entriesToRun: entriesToRun, simulator: simulator),
                environment: testContext.environment,
                maximumAllowedSilenceDuration: configuration.maximumAllowedSilenceDuration ?? 0),
            simulatorId: simulator.identifier,
            singleTestMaximumDuration: configuration.singleTestMaximumDuration)
        fbxctestOutputProcessor.processOutputAndWaitForProcessTermination()
        
        let result = prepareResults(
            requestedEntriesToRun: entriesToRun,
            testEventPairs: fbxctestOutputProcessor.testEventPairs)
        
        eventBus.post(event: .runnerEvent(.didRun(testEntries: entriesToRun, testContext: testContext, results: result)))
        
        log("Attempted to run \(entriesToRun.count) tests on simulator \(simulator): \(entriesToRun)", color: .blue)
        log("Did get \(result.count) results: \(result)", color: .boldBlue)
        
        return result
    }
    
    private func fbxctestArguments(entriesToRun: [TestEntry], simulator: Simulator) -> [String] {
        var arguments =
            [configuration.auxiliaryPaths.fbxctest,
             "-destination", simulator.testDestination.destinationString] +
                ["-\(configuration.testType.rawValue)"]
        
        let buildArtifacts = configuration.buildArtifacts
        switch configuration.testType {
        case .logicTest:
            arguments += ["\(buildArtifacts.xcTestBundle)"]
        case .appTest:
            arguments += ["\(buildArtifacts.xcTestBundle):\(buildArtifacts.appBundle)"]
        case .uiTest:
            let components = [buildArtifacts.xcTestBundle, buildArtifacts.runner, buildArtifacts.appBundle]
                + buildArtifacts.additionalApplicationBundles
            
            arguments += [components.joined(separator: ":")]
            if let simulatorLocatizationSettings = configuration.simulatorSettings.simulatorLocalizationSettings {
                arguments += ["-simulator-localization-settings", simulatorLocatizationSettings]
            }
            if let watchdogSettings = configuration.simulatorSettings.watchdogSettings {
                arguments += ["-watchdog-settings", watchdogSettings]
            }
        }
        
        arguments += entriesToRun.flatMap { ["-only", "\(buildArtifacts.xcTestBundle):\($0.testName)"] }
        arguments += ["run-tests", "-sdk", "iphonesimulator"]
      
        if type(of: simulator) != Shimulator.self {
            arguments += ["-workingDirectory", simulator.workingDirectory]
        }
        
        arguments += ["-keep-simulators-alive"]
        
        if let oslogPath = configuration.testDiagnosticOutput.oslogOutputPath {
            arguments += ["-oslog", oslogPath]
        }
        if let videoPath = configuration.testDiagnosticOutput.videoOutputPath {
            arguments += ["-video", videoPath]
        }
        if let testLogPath = configuration.testDiagnosticOutput.testLogOutputPath {
            arguments += ["-testlog", testLogPath]
        }
        return arguments
    }
    
    private func testContext(simulator: Simulator) -> TestContext {
        var environment = configuration.environment
        let testsWorkingDirectory = configuration.auxiliaryPaths.tempFolder.appending(pathComponents: ["testsWorkingDir", UUID().uuidString])
        do {
            try FileManager.default.createDirectory(atPath: testsWorkingDirectory, withIntermediateDirectories: true, attributes: nil)
            environment[RunnerConstants.envTestsWorkingDirectory.rawValue] = testsWorkingDirectory
        } catch {
            log("Error: unable to create path: '\(testsWorkingDirectory)'", color: .red)
        }
        return TestContext(environment: environment, testDestination: simulator.testDestination)
    }
    
    private func prepareResults(
        requestedEntriesToRun: [TestEntry],
        testEventPairs: [TestEventPair])
        -> [TestRunResult]
    {
        return requestedEntriesToRun.compactMap { requestedEntryToRun in
            prepareResult(
                requestedEntryToRun: requestedEntryToRun,
                testEventPairs: testEventPairs)
        }
    }
    
    private func prepareResult(
        requestedEntryToRun: TestEntry,
        testEventPairs: [TestEventPair])
        -> TestRunResult?
    {
        let correspondingEventPair = testEventPairForEntry(
            requestedEntryToRun,
            testEventPairs: testEventPairs)
        
        if let correspondingEventPair = correspondingEventPair, let finishEvent = correspondingEventPair.finishEvent {
            return TestRunResult(
                testEntry: requestedEntryToRun,
                succeeded: finishEvent.succeeded,
                exceptions: finishEvent.exceptions.map { TestException(reason: $0.reason, filePathInProject: $0.filePathInProject, lineNumber: $0.lineNumber) },
                duration: finishEvent.totalDuration,
                startTime: correspondingEventPair.startEvent.timestamp,
                finishTime: finishEvent.timestamp,
                hostName: correspondingEventPair.startEvent.hostName ?? "host was not set to TestStartedEvent",
                processId: correspondingEventPair.startEvent.processId ?? 0,
                simulatorId: correspondingEventPair.startEvent.simulatorId ?? "unknown_simulator")
        } else {
            return nil
        }
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
        collectedResults: [TestRunResult])
        -> [TestEntry]
    {
        let receivedTestNames = Set(collectedResults.map { $0.testEntry.testName })
        return expectedEntriesToRun.filter { !receivedTestNames.contains($0.testName) }
    }
    
    private func resultsForTestsThatDidNotRun(
        testEntries: [TestEntry],
        resultsForFinishedTests: [TestRunResult])
        -> [TestRunResult]
    {
        let testNamesForFinishedTests = Set(resultsForFinishedTests.map { $0.testEntry.testName })
        
        return testEntries.compactMap { testEntry in
            if testNamesForFinishedTests.contains(testEntry.testName) {
                return nil
            } else {
                return resultForSingleTestThatDidNotRun(testEntry: testEntry)
            }
        }
    }
    
    private func resultForSingleTestThatDidNotRun(testEntry: TestEntry) -> TestRunResult {
        let timestamp = Date().timeIntervalSince1970
        return TestRunResult(
            testEntry: testEntry,
            succeeded: false,
            exceptions: [
                TestException(
                    reason: RunnerConstants.testDidNotRun.rawValue,
                    filePathInProject: #file,
                    lineNumber: #line)
            ],
            duration: 0,
            startTime: timestamp,
            finishTime: timestamp,
            hostName: HostDeterminer.currentHostAddress,
            processId: 0,
            simulatorId: "no_simulator")
    }
}
