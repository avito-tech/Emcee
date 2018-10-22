import EventBus
import Foundation
import Models
import Logging
import Runner
import SimulatorPool
import TempFolder

public struct RuntimeQueryResult {
    public let unavailableTestsToRun: [TestToRun]
    public let availableRuntimeTests: [RuntimeTestEntry]
}

public final class RuntimeTestQuerier {
    public enum TestExplorationError: Error, CustomStringConvertible {
        case fileNotFound(String)
        
        public var description: String {
            switch self {
            case .fileNotFound(let path):
                return "Runtime dump did not create a JSON file at expected location: '\(path)'."
            }
        }
    }
    
    private let eventBus: EventBus
    private let configuration: RuntimeDumpConfiguration
    private let testQueryEntry = TestEntry(className: "NonExistingTest", methodName: "fakeTest", caseId: nil)
    
    public init(eventBus: EventBus, configuration: RuntimeDumpConfiguration) {
        self.eventBus = eventBus
        self.configuration = configuration
    }
    
    public func queryRuntime() throws -> RuntimeQueryResult {
        let availableRuntimeTests = try availableTestsInRuntime()
        let unavailableTestEntries = requestedTestEntriesNotAvailableInRuntime(availableRuntimeTests)
        return RuntimeQueryResult(
            unavailableTestsToRun: unavailableTestEntries,
            availableRuntimeTests: availableRuntimeTests)
    }
    
    private func availableTestsInRuntime() throws -> [RuntimeTestEntry] {
        let runtimeEntriesJSONPath = NSTemporaryDirectory().appending("runtime_tests.json")
        log("Will dump runtime tests into file: \(runtimeEntriesJSONPath)", color: .boldBlue)
        
        let runnerConfiguration = RunnerConfiguration(
            testType: .logicTest,
            auxiliaryPaths: AuxiliaryPaths(fbxctest: configuration.fbxctest, fbsimctl: .void, plugins: []),
            buildArtifacts: BuildArtifacts.onlyWithXctestBundle(xcTestBundle: configuration.xcTestBundle),
            testExecutionBehavior: configuration.testExecutionBehavior.withEnvironmentOverrides(
                ["AVITO_TEST_RUNNER_RUNTIME_TESTS_EXPORT_PATH": runtimeEntriesJSONPath]),
            simulatorSettings: configuration.simulatorSettings,
            testTimeoutConfiguration: configuration.testTimeoutConfiguration,
            testDiagnosticOutput: try TestDiagnosticOutput(
                iOSVersion: configuration.testDestination.iOSVersion,
                videoOutputPath: nil,
                oslogOutputPath: nil,
                testLogOutputPath: nil))
        _ = try Runner(eventBus: eventBus, configuration: runnerConfiguration, tempFolder: try TempFolder())
            .runOnce(
                entriesToRun: [testQueryEntry],
                onSimulator: Shimulator.shimulator(testDestination: configuration.testDestination))
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: runtimeEntriesJSONPath)),
            let foundTestEntries = try? JSONDecoder().decode([RuntimeTestEntry].self, from: data) else {
                throw TestExplorationError.fileNotFound(runtimeEntriesJSONPath)
        }
        
        let allTests = foundTestEntries.flatMap { $0.testMethods }
        log("Runtime dump contains \(foundTestEntries.count) XCTestCases, \(allTests.count) tests")
        
        return foundTestEntries
    }
    
    private func requestedTestEntriesNotAvailableInRuntime(_ runtimeDetectedEntries: [RuntimeTestEntry]) -> [TestToRun] {
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
