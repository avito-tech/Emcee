import Foundation
import Models
import ProcessController

public protocol TestRunner {
    func run(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        maximumAllowedSilenceDuration: TimeInterval,
        simulatorSettings: SimulatorSettings,
        singleTestMaximumDuration: TimeInterval,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig
}

