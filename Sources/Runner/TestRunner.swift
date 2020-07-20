import BuildArtifacts
import DeveloperDirLocator
import Foundation
import Logging
import Models
import ProcessController
import RunnerModels
import SimulatorPoolModels
import TemporaryStuff

public protocol TestRunnerRunningInvocation {
    var output: StandardStreamsCaptureConfig { get }
    var subprocessInfo: SubprocessInfo { get }
    func cancel()
    func wait()
}

public protocol TestRunnerInvocation {
    func startExecutingTests() -> TestRunnerRunningInvocation
}

public protocol TestRunner {
    func prepareTestRun(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        simulator: Simulator,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> TestRunnerInvocation
}

