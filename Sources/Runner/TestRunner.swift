import Foundation
import DeveloperDirLocator
import Models
import ProcessController
import TemporaryStuff

public protocol TestRunner {
    func run(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        maximumAllowedSilenceDuration: TimeInterval,
        simulatorSettings: SimulatorSettings,
        singleTestMaximumDuration: TimeInterval,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType,
        temporaryFolder: TemporaryFolder
    ) throws -> StandardStreamsCaptureConfig
}

