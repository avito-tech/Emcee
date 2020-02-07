import DateProvider
import DeveloperDirLocator
import Foundation
import Logging
import Models
import ProcessController
import ResourceLocationResolver
import Runner
import SimulatorPool
import TemporaryStuff

public final class XcodebuildBasedTestRunner: TestRunner {
    private let dateProvider: DateProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        dateProvider: DateProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.dateProvider = dateProvider
        self.processControllerProvider = processControllerProvider
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
        let xcodebuildLogParser = try XcodebuildLogParser(dateProvider: dateProvider)
        
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "xcodebuild",
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
                    ),
                    "-parallel-testing-enabled", "NO",
                    "test-without-building",
                ],
                environment: testContext.environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: testTimeoutConfiguration.testRunnerMaximumSilenceDuration
                )
            )
        )
        
        processController.onStdout { sender, data, unsubscribe in
            let stopOnFailure = {
                unsubscribe()
                sender.interruptAndForceKillIfNeeded()
            }
            
            guard let string = String(data: data, encoding: .utf8) else {
                Logger.warning("Can't obtain string from xcodebuild stdout \(data.count) bytes")
                return stopOnFailure()
            }
            
            do {
                try xcodebuildLogParser.parse(string: string, testRunnerStream: testRunnerStream)
            } catch {
                Logger.error("Failed to parse xcodebuild output: \(error)")
                return stopOnFailure()
            }
        }
        
        try processController.startAndWaitForSuccessfulTermination()
        return processController.subprocess.standardStreamsCaptureConfig
    }
}
