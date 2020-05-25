import BuildArtifacts
import DeveloperDirLocator
import Foundation
import Models
import ProcessController
import SimulatorPoolModels
import TemporaryStuff

public protocol TestRunner {
    func run(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        simulator: Simulator,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig
}

