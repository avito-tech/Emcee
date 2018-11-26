import EventBus
import Foundation
import Models
import Logging
import ResourceLocationResolver
import Runner
import SimulatorPool
import TempFolder

public final class RuntimeTestQuerier {
    private let eventBus: EventBus
    private let configuration: RuntimeDumpConfiguration
    private let testQueryEntry = TestEntry(className: "NonExistingTest", methodName: "fakeTest", caseId: nil)
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TempFolder
    static let runtimeTestsJsonFilename = "runtime_tests.json"
    
    public init(
        eventBus: EventBus,
        configuration: RuntimeDumpConfiguration,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TempFolder)
    {
        self.eventBus = eventBus
        self.configuration = configuration
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
    }
    
    public func queryRuntime() throws -> RuntimeQueryResult {
        let availableRuntimeTests = try availableTestsInRuntime()
        let unavailableTestEntries = requestedTestsNotAvailableInRuntime(availableRuntimeTests)
        return RuntimeQueryResult(
            unavailableTestsToRun: unavailableTestEntries,
            availableRuntimeTests: availableRuntimeTests)
    }
    
    private func availableTestsInRuntime() throws -> [RuntimeTestEntry] {
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [RuntimeTestQuerier.runtimeTestsJsonFilename])
        log("Will dump runtime tests into file: \(runtimeEntriesJSONPath)", color: .boldBlue)
        
        let runnerConfiguration = RunnerConfiguration(
            testType: .logicTest,
            fbxctest: configuration.fbxctest,
            buildArtifacts: BuildArtifacts.onlyWithXctestBundle(xcTestBundle: configuration.xcTestBundle),
            testRunExecutionBehavior: configuration.testRunExecutionBehavior.withEnvironmentOverrides(
                ["AVITO_TEST_RUNNER_RUNTIME_TESTS_EXPORT_PATH": runtimeEntriesJSONPath.asString]),
            simulatorSettings: configuration.simulatorSettings,
            testTimeoutConfiguration: configuration.testTimeoutConfiguration)
        _ = try Runner(
            eventBus: eventBus,
            configuration: runnerConfiguration,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver)
            .runOnce(
                entriesToRun: [testQueryEntry],
                onSimulator: Shimulator.shimulator(testDestination: configuration.testDestination))
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: runtimeEntriesJSONPath.asString)),
            let foundTestEntries = try? JSONDecoder().decode([RuntimeTestEntry].self, from: data) else {
                throw TestExplorationError.fileNotFound(runtimeEntriesJSONPath.asString)
        }
        
        let allTests = foundTestEntries.flatMap { $0.testMethods }
        log("Runtime dump contains \(foundTestEntries.count) XCTestCases, \(allTests.count) tests")
        
        return foundTestEntries
    }
    
    private func requestedTestsNotAvailableInRuntime(_ runtimeDetectedEntries: [RuntimeTestEntry]) -> [TestToRun] {
        if configuration.testsToRun.isEmpty { return [] }
        if runtimeDetectedEntries.isEmpty { return configuration.testsToRun }
        
        let availableTestEntries = runtimeDetectedEntries.flatMap { runtimeDetectedTestEntry -> [TestEntry] in
            runtimeDetectedTestEntry.testMethods.map {
                TestEntry(className: runtimeDetectedTestEntry.className, methodName: $0, caseId: runtimeDetectedTestEntry.caseId)
            }
        }
        let testsToRunMissingInRuntime = configuration.testsToRun.filter { requestedTestToRun -> Bool in
            switch requestedTestToRun {
            case .testName(let requestedTestName):
                return availableTestEntries.first { $0.testName == requestedTestName } == nil
            case .caseId(let requestedCaseId):
                return availableTestEntries.first { $0.caseId == requestedCaseId } == nil
            }
        }
        return testsToRunMissingInRuntime
    }
}
