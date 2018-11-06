import EventBus
import Extensions
import fbxctest
import Foundation
import Models
import TempFolder
import TestingFakeFbxctest
import ResourceLocationResolver
import Runner
import ScheduleStrategy
import SimulatorPool
import XCTest

public final class RunnerTests: XCTestCase {
    let shimulator = Shimulator.shimulator(testDestination: try! TestDestination(deviceType: "iPhone SE", iOSVersion: "11.4"))
    let testClassName = "ClassName"
    let testMethod = "testMethod"
    var tempFolder: TempFolder!
    let testExceptionEvent = TestExceptionEvent(reason: "a reason", filePathInProject: "file", lineNumber: 12)
    let resolver = ResourceLocationResolver()
    
    public override func setUp() {
        XCTAssertNoThrow(tempFolder = try TempFolder())
    }
    
    func testRunningTestWithoutAnyFeedbackEventsGivesFailureResults() throws {
        let runId = UUID().uuidString
        // do not stub, simulating a crash/silent exit
        
        let testEntry = TestEntry(className: testClassName, methodName: testMethod, caseId: nil)
        let results = try runTestEntries([testEntry], runId: runId)
        
        XCTAssertEqual(results.count, 1)
        let testResult = results[0]
        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(testResult.testRunResults[0].exceptions[0].reason, RunnerConstants.testDidNotRun.rawValue)
    }

    func testRunningSuccessfulTestGivesPositiveResults() throws {
        let runId = UUID().uuidString
        try stubFbxctestEvent(runId: runId, success: true)
        
        let testEntry = TestEntry(className: testClassName, methodName: testMethod, caseId: nil)
        let results = try runTestEntries([testEntry], runId: runId)
        
        XCTAssertEqual(results.count, 1)
        let testResult = results[0]
        XCTAssertTrue(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }
    
    func testRunningFailedTestGivesNegativeResults() throws {
        let runId = UUID().uuidString
        try stubFbxctestEvent(runId: runId, success: false)
        
        let testEntry = TestEntry(className: testClassName, methodName: testMethod, caseId: nil)
        let results = try runTestEntries([testEntry], runId: runId)
        
        XCTAssertEqual(results.count, 1)
        let testResult = results[0]
        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(
            testResult.testRunResults[0].exceptions,
            [TestException(reason: "a reason", filePathInProject: "file", lineNumber: 12)])
    }
    
    func testRunningCrashedTestRevivesItAndIfTestSuccedsReturnsPositiveResults() throws {
        let runId = UUID().uuidString
        try FakeFbxctestExecutableProducer.setFakeOutputEvents(runId: runId, runIndex: 0, [
            AnyEncodableWrapper(
                TestStartedEvent(
                    test: "\(testClassName)/\(testMethod)",
                    className: testClassName,
                    methodName: testMethod,
                    timestamp: Date().timeIntervalSince1970)),
            ])
        try stubFbxctestEvent(runId: runId, success: true, runIndex: 1)
        
        let testEntry = TestEntry(className: testClassName, methodName: testMethod, caseId: nil)
        let results = try runTestEntries([testEntry], runId: runId)
        
        XCTAssertEqual(results.count, 1)
        let testResult = results[0]
        XCTAssertTrue(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }
    
    private func runTestEntries(_ testEntries: [TestEntry], runId: String) throws -> [TestEntryResult] {
        let runner = Runner(
            eventBus: EventBus(),
            configuration: try createRunnerConfig(runId: runId),
            tempFolder: tempFolder,
            resourceLocationResolver: resolver)
        return try runner.run(entries: testEntries, onSimulator: shimulator)
    }
    
    private func stubFbxctestEvent(runId: String, success: Bool, runIndex: Int = 0) throws {
        try FakeFbxctestExecutableProducer.setFakeOutputEvents(runId: runId, runIndex: runIndex, [
            AnyEncodableWrapper(
                TestStartedEvent(
                    test: "\(testClassName)/\(testMethod)",
                    className: testClassName,
                    methodName: testMethod,
                    timestamp: Date().timeIntervalSince1970)),
            AnyEncodableWrapper(
                TestFinishedEvent(
                    test: "\(testClassName)/\(testMethod)",
                    result: success ? "success" : "failure",
                    className: testClassName,
                    methodName: testMethod,
                    totalDuration: 0.5,
                    exceptions: success ? [] : [testExceptionEvent],
                    succeeded: success,
                    output: "",
                    logs: [],
                    timestamp: Date().timeIntervalSince1970 + 0.5))
            ])
    }
    
    private func createRunnerConfig(runId: String) throws -> RunnerConfiguration {
        let fbxctest = try FakeFbxctestExecutableProducer.fakeFbxctestPath(runId: runId)
        addTeardownBlock {
            try? FileManager.default.removeItem(atPath: fbxctest)
        }
        
        let configuration = RunnerConfiguration(
            testType: .logicTest,
            fbxctest: .localFilePath(fbxctest),
            buildArtifacts: BuildArtifacts(
                appBundle: "",
                runner: "",
                xcTestBundle: "",
                additionalApplicationBundles: []),
            testExecutionBehavior: TestExecutionBehavior(
                numberOfRetries: 1,
                numberOfSimulators: 1,
                environment: ["EMCEE_TESTS_RUN_ID": runId],
                scheduleStrategy: .individual),
            simulatorSettings: SimulatorSettings(
                simulatorLocalizationSettings: "",
                watchdogSettings: ""),
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 5),
            testDiagnosticOutput: TestDiagnosticOutput.nullOutput)
        return configuration
    }
}

extension TestException: Equatable {
    public static func == (l: TestException, r: TestException) -> Bool {
        return l.reason == r.reason &&
            l.filePathInProject == r.filePathInProject &&
            l.lineNumber == r.lineNumber
    }
}
