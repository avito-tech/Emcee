import Foundation
import Models
import ProcessController
import Runner

public final class FakeTestRunner: TestRunner {
    public var buildArtifacts: BuildArtifacts?
    public var entriesToRun: [TestEntry]?
    public var maximumAllowedSilenceDuration: TimeInterval?
    public var simulatorSettings: SimulatorSettings?
    public var singleTestMaximumDuration: TimeInterval?
    public var testContext: TestContext?
    public var testRunnerStream: TestRunnerStream?
    public var testType: TestType?

    public let runningQueue = DispatchQueue(label: "FakeTestRunner")

    public var standardStreamsCaptureConfig = StandardStreamsCaptureConfig(
        stdoutContentsFile: nil,
        stderrContentsFile: nil,
        stdinContentsFile: nil
    )

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

    // - TestRunner Protocol

    public func run(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        maximumAllowedSilenceDuration: TimeInterval,
        simulatorSettings: SimulatorSettings,
        singleTestMaximumDuration: TimeInterval,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig {
        self.buildArtifacts = buildArtifacts
        self.entriesToRun = entriesToRun
        self.maximumAllowedSilenceDuration = maximumAllowedSilenceDuration
        self.simulatorSettings = simulatorSettings
        self.singleTestMaximumDuration = singleTestMaximumDuration
        self.testContext = testContext
        self.testRunnerStream = testRunnerStream
        self.testType = testType

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

