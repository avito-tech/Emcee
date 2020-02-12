import DeveloperDirLocator
import Foundation
import Models
import ProcessController
import Runner
import SimulatorPoolModels
import TemporaryStuff

public final class FakeTestRunner: TestRunner {
    public var buildArtifacts: BuildArtifacts?
    public var entriesToRun: [TestEntry]?
    public var errorToThrowOnRun: Error?
    public var simulatorSettings: SimulatorSettings?
    public var testContext: TestContext?
    public var testRunnerStream: TestRunnerStream?
    public var testTimeoutConfiguration: TestTimeoutConfiguration?
    public var testType: TestType?

    public let runningQueue = DispatchQueue(label: "FakeTestRunner")

    public var standardStreamsCaptureConfig = StandardStreamsCaptureConfig()
    
    public struct SomeError: Error, CustomStringConvertible {
        public let description = "some error happened"
        public init() {}
    }
    
    public init() {}
    

    // Configuration

    public static func testStartedHandlerForNormalEventStreaming() -> (TestName, TestRunnerStream) -> () {
        return { testName, testRunnerStream in
            testRunnerStream.testStarted(testName: testName)
        }
    }

    public static func testStoppedHandlerForNormalEventStreaming() -> (TestStoppedEvent, TestRunnerStream) -> () {
        return { testStoppedEvent, testRunnerStream in
            testRunnerStream.testStopped(
                testStoppedEvent: testStoppedEvent
            )
        }
    }

    public var onTestStarted: (TestName, TestRunnerStream) -> () =
        FakeTestRunner.testStartedHandlerForNormalEventStreaming()

    public var onExecuteTest: (TestName) -> TestStoppedEvent.Result = { _ in .success }

    public var onTestStopped: (TestStoppedEvent, TestRunnerStream) -> () =
        FakeTestRunner.testStoppedHandlerForNormalEventStreaming()

    public func disableTestStartedTestRunnerStreamEvents() {
        onTestStarted = { _, _ in }
    }

    public func disableTestStoppedTestRunnerStreamEvents() {
        onTestStopped = { _, _ in }
    }
    
    public func makeRunThrowErrors() {
        errorToThrowOnRun = SomeError()
    }

    // - TestRunner Protocol
    public var isRunCalled = false
    public func run(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        simulator: Simulator,
        simulatorSettings: SimulatorSettings,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig {
        isRunCalled = true

        self.buildArtifacts = buildArtifacts
        self.entriesToRun = entriesToRun
        self.simulatorSettings = simulatorSettings
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testContext = testContext
        self.testRunnerStream = testRunnerStream
        self.testType = testType
        
        if let errorToThrowOnRun = errorToThrowOnRun {
            throw errorToThrowOnRun
        }

        let group = DispatchGroup()

        for testEntry in entriesToRun {
            group.enter()

            runningQueue.async {
                let testStartTimestamp = Date()
                self.onTestStarted(testEntry.testName, testRunnerStream)

                self.runningQueue.async {
                    let testResult = self.onExecuteTest(testEntry.testName)

                    self.runningQueue.async {
                        let testStoppedEvent = TestStoppedEvent(
                            testName: testEntry.testName,
                            result: testResult,
                            testDuration: Date().timeIntervalSince(testStartTimestamp),
                            testExceptions: [],
                            testStartTimestamp: testStartTimestamp.timeIntervalSince1970
                        )

                        self.onTestStopped(testStoppedEvent, testRunnerStream)

                        group.leave()
                    }
                }
            }
        }

        group.wait()

        return standardStreamsCaptureConfig
    }
}

