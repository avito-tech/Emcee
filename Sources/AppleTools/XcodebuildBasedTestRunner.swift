import DeveloperDirLocator
import Foundation
import Models
import ProcessController
import ResourceLocationResolver
import Runner
import SimulatorPool
import TemporaryStuff

public final class XcodebuildBasedTestRunner: TestRunner {
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.resourceLocationResolver = resourceLocationResolver
    }
    
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
        let processController = try DefaultProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "xcodebuild", "test-without-building",
                    "-destination", XcodebuildSimulatorDestinationArgument(
                        destinationId: simulator.udid
                    ),
                    "-xctestrun", XcTestRunFileArgument(
                        buildArtifacts: buildArtifacts,
                        developerDirLocator: developerDirLocator,
                        entriesToRun: entriesToRun,
                        resourceLocationResolver: resourceLocationResolver,
                        temporaryFolder: temporaryFolder,
                        testContext: testContext,
                        testType: testType
                    )
                ],
                environment: testContext.environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: testTimeoutConfiguration.testRunnerMaximumSilenceDuration
                )
            )
        )
        processController.startAndListenUntilProcessDies()
        return processController.subprocess.standardStreamsCaptureConfig
    }
}
