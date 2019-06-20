import EventBus
import Extensions
import fbxctest
import Foundation
import Models
import ModelsTestHelpers
import TempFolder
import TestingFakeFbxctest
import ResourceLocationResolver
import Runner
import ScheduleStrategy
import SimulatorPool
import XCTest

public final class RunnerTests: XCTestCase {
    lazy var shimulator = Shimulator.shimulator(
        testDestination: TestDestinationFixtures.testDestination,
        workingDirectory: tempFolder.pathWith(components: [])
    )
    let testClassName = "ClassName"
    let testMethod = "testMethod"
    var tempFolder: TempFolder!
    let testExceptionEvent = FbXcTestExceptionEvent(reason: "a reason", filePathInProject: "file", lineNumber: 12)
    let resolver = ResourceLocationResolver()
    let runId = UUID().uuidString
    
    public override func setUp() {
        XCTAssertNoThrow(tempFolder = try TempFolder())
    }
    
    func testRunningTestWithoutAnyFeedbackEventsGivesFailureResults() throws {
        // do not stub, simulating a crash/silent exit
        
        let testEntry = TestEntryFixtures.testEntry(className: testClassName, methodName: testMethod)
        let runnerRunResults = try runTestEntries([testEntry], runId: runId)
        
        XCTAssertEqual(runnerRunResults.testEntryResults.count, 1)
        let testResult = runnerRunResults.testEntryResults[0]
        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(testResult.testRunResults[0].exceptions[0].reason, RunnerConstants.testDidNotRun.rawValue)
    }

    func testRunningSuccessfulTestGivesPositiveResults() throws {
        try stubFbxctestEvent(runId: runId, success: true)
        
        let testEntry = TestEntryFixtures.testEntry(className: testClassName, methodName: testMethod)
        let runnerRunResults = try runTestEntries([testEntry], runId: runId)
        
        XCTAssertEqual(runnerRunResults.testEntryResults.count, 1)
        let testResult = runnerRunResults.testEntryResults[0]
        XCTAssertTrue(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }
    
    func testRunningFailedTestGivesNegativeResults() throws {
        try stubFbxctestEvent(runId: runId, success: false)
        
        let testEntry = TestEntryFixtures.testEntry(className: testClassName, methodName: testMethod)
        let runnerRunResults = try runTestEntries([testEntry], runId: runId)
        
        XCTAssertEqual(runnerRunResults.testEntryResults.count, 1)
        let testResult = runnerRunResults.testEntryResults[0]
        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(
            testResult.testRunResults[0].exceptions,
            [TestException(reason: "a reason", filePathInProject: "file", lineNumber: 12)])
    }
    
    func testRunningCrashedTestRevivesItAndIfTestSuccedsReturnsPositiveResults() throws {
        try FakeFbxctestExecutableProducer.setFakeOutputEvents(runId: runId, runIndex: 0, [
            AnyEncodableWrapper(
                FbXcTestStartedEvent(
                    test: "\(testClassName)/\(testMethod)",
                    className: testClassName,
                    methodName: testMethod,
                    timestamp: Date().timeIntervalSince1970)),
            ])
        try stubFbxctestEvent(runId: runId, success: true, runIndex: 1)
        
        let testEntry = TestEntryFixtures.testEntry(className: testClassName, methodName: testMethod)
        let runnerRunResults = try runTestEntries([testEntry], runId: runId)
        
        XCTAssertEqual(runnerRunResults.testEntryResults.count, 1)
        let testResult = runnerRunResults.testEntryResults[0]
        XCTAssertTrue(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }
    
    private func runTestEntries(_ testEntries: [TestEntry], runId: String) throws -> RunnerRunResult {
        let runner = Runner(
            eventBus: EventBus(),
            configuration: try createRunnerConfig(runId: runId),
            tempFolder: tempFolder,
            resourceLocationResolver: resolver)
        return try runner.run(entries: testEntries, simulator: shimulator)
    }
    
    private func stubFbxctestEvent(runId: String, success: Bool, runIndex: Int = 0) throws {
        try FakeFbxctestExecutableProducer.setFakeOutputEvents(runId: runId, runIndex: runIndex, [
            AnyEncodableWrapper(
                FbXcTestStartedEvent(
                    test: "\(testClassName)/\(testMethod)",
                    className: testClassName,
                    methodName: testMethod,
                    timestamp: Date().timeIntervalSince1970)),
            AnyEncodableWrapper(
                FbXcTestFinishedEvent(
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
        
        return RunnerConfiguration(
            testType: .logicTest,
            fbxctest: FbxctestLocation(.localFilePath(fbxctest)),
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            environment: ["EMCEE_TESTS_RUN_ID": runId],
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 5)
        )
    }
}
