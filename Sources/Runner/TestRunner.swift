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
        maximumAllowedSilenceDuration: TimeInterval,
        simulator: Simulator,
        simulatorSettings: SimulatorSettings,
        singleTestMaximumDuration: TimeInterval,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig
}

