import DeveloperDirLocator
import Foundation
import Models
import ProcessController
import ResourceLocationResolver
import Runner
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
        maximumAllowedSilenceDuration: TimeInterval,
        simulatorSettings: SimulatorSettings,
        singleTestMaximumDuration: TimeInterval,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType,
        temporaryFolder: TemporaryFolder
    ) throws -> StandardStreamsCaptureConfig {
        let processController = try ProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "xcodebuild", "test-without-building",
                    "-destination", XcodebuildSimulatorDestinationArgument(
                        simulatorInfo: testContext.simulatorInfo,
                        testType: testType
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
                    allowedSilenceDuration: maximumAllowedSilenceDuration
                )
            )
        )
        processController.startAndListenUntilProcessDies()
        return processController.subprocess.standardStreamsCaptureConfig
    }
}
