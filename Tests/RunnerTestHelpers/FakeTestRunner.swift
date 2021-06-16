import BuildArtifacts
import DeveloperDirLocator
import EmceeLogging
import Foundation
import ProcessController
import Runner
import RunnerModels
import SimulatorPoolModels
import Tmp
import PathLib

public final class FakeTestRunner: TestRunner {
    public var entriesToRun: [TestEntry]?
    public var errorToThrowOnRun: Error?
    public var testContext: TestContext?
    private let tempFolder: TemporaryFolder
    
    public struct SomeError: Error, CustomStringConvertible {
        public let description = "some error happened"
        public init() {}
    }
    
    public init(tempFolder: TemporaryFolder) {
        self.tempFolder = tempFolder
    }

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
    
    public var onStreamOpen: (TestRunnerStream) -> () = {
        $0.openStream()
    }

    public var onTestStarted: (TestName, TestRunnerStream) -> () =
        FakeTestRunner.testStartedHandlerForNormalEventStreaming()

    public var onExecuteTest: (TestName) -> TestStoppedEvent.Result = { _ in .success }

    public var onTestStopped: (TestStoppedEvent, TestRunnerStream) -> () =
        FakeTestRunner.testStoppedHandlerForNormalEventStreaming()
    
    public var onStreamClose: (TestRunnerStream) -> () = {
        $0.closeStream()
    }

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
    
    public func prepareTestRun(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        logger: ContextualLogger,
        runnerWasteCollector: RunnerWasteCollector,
        simulator: Simulator,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> TestRunnerInvocation {
        isRunCalled = true

        self.entriesToRun = entriesToRun
        self.testContext = testContext
        
        if let errorToThrowOnRun = errorToThrowOnRun {
            throw errorToThrowOnRun
        }
        
        return FakeTestRunnerInvocation(
            entriesToRun: entriesToRun,
            testRunnerStream: testRunnerStream,
            testResultProvider: onExecuteTest,
            onStreamOpen: onStreamOpen,
            onTestStarted: onTestStarted,
            onTestStopped: onTestStopped,
            onStreamClose: onStreamClose,
            tempFolder: tempFolder
        )
    }
    
    public var isAdditionalEnvironmentCalled = false
    public var additionalEnvironmentReturns: [String: String] = [:]
    
    public func additionalEnvironment(testRunnerWorkingDirectory: AbsolutePath) -> [String : String] {
        isAdditionalEnvironmentCalled = true
        return additionalEnvironmentReturns
    }
}
