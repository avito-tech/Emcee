import DeveloperDirLocator
import Foundation
import Models
import ProcessController
import SimulatorPool
import TemporaryStuff

public protocol TestRunner {
    func run(
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
    ) throws -> StandardStreamsCaptureConfig
}

