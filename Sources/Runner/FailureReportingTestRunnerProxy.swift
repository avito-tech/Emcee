import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import EmceeLogging
import SimulatorPoolModels
import Tmp
import RunnerModels
import Foundation

public final class FailureReportingTestRunnerProxy: TestRunner {
    private let dateProvider: DateProvider
    private let testRunner: TestRunner
    
    public init(
        dateProvider: DateProvider,
        testRunner: TestRunner
    ) {
        self.dateProvider = dateProvider
        self.testRunner = testRunner
    }
    
    public func prepareTestRun(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        logger: ContextualLogger,
        runnerWasteCollector: RunnerWasteCollector,
        simulator: Simulator,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> TestRunnerInvocation {
        do {
            return try testRunner.prepareTestRun(
                buildArtifacts: buildArtifacts, 
                developerDirLocator: developerDirLocator, 
                entriesToRun: entriesToRun, 
                logger: logger, 
                runnerWasteCollector: runnerWasteCollector, 
                simulator: simulator, 
                temporaryFolder: temporaryFolder, 
                testContext: testContext, 
                testRunnerStream: testRunnerStream, 
                testType: testType
            )
        } catch {
            return generateFailureResults(
                entriesToRun: entriesToRun,
                runnerError: error,
                testRunnerStream: testRunnerStream
            )
        }
    }
    
    private func generateFailureResults(
        entriesToRun: [TestEntry],
        runnerError: Error,
        testRunnerStream: TestRunnerStream
    ) -> TestRunnerInvocation {
        testRunnerStream.openStream()
        for testEntry in entriesToRun {
            testRunnerStream.testStarted(testName: testEntry.testName)
            testRunnerStream.testStopped(
                testStoppedEvent: TestStoppedEvent(
                    testName: testEntry.testName,
                    result: .lost,
                    testDuration: 0,
                    testExceptions: [
                        RunnerConstants.failedToStartTestRunner(runnerError).testException
                    ],
                    testStartTimestamp: dateProvider.currentDate().timeIntervalSince1970
                )
            )
        }
        testRunnerStream.closeStream()
        return NoOpTestRunnerInvocation()
    }
}

private class NoOpTestRunnerInvocation: TestRunnerInvocation {
    private class NoOpTestRunnerRunningInvocation: TestRunnerRunningInvocation {
        init() {}
        let pidInfo = PidInfo(pid: 0, name: "no-op process")
        func cancel() {}
        func wait() {}
    }
    
    init() {}
    
    func startExecutingTests() -> TestRunnerRunningInvocation { NoOpTestRunnerRunningInvocation() }
}
