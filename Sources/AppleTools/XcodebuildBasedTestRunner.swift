import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import Foundation
import EmceeLogging
import ObservableFileReader
import ProcessController
import ResourceLocationResolver
import ResultStream
import Runner
import RunnerModels
import SimulatorPoolModels
import Tmp
import PathLib

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
        let invocationPath = try temporaryFolder.pathByCreatingDirectories(components: [testContext.contextId])
        runnerWasteCollector.scheduleCollection(path: invocationPath)
        
        let resultStreamFile = try temporaryFolder.createFile(components: [testContext.contextId], filename: "result_stream.json")
        let xcTestRunFile = XcTestRunFileArgument(
            buildArtifacts: buildArtifacts,
            entriesToRun: entriesToRun,
            containerPath: invocationPath,
            resourceLocationResolver: resourceLocationResolver,
            testContext: testContext,
            testType: testType,
            testingEnvironment: XcTestRunTestingEnvironment(insertedLibraries: [])
        )
        
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "xcodebuild",
                    "-destination", XcodebuildSimulatorDestinationArgument(destinationId: simulator.udid),
                    "-derivedDataPath", invocationPath.appending(component: "derivedData"),
                    "-resultBundlePath", invocationPath.appending(component: "resultBundle"),
                    "-resultStreamPath", resultStreamFile,
                    "-xctestrun", xcTestRunFile,
                    "-parallel-testing-enabled", "NO",
                    "test-without-building",
                ],
                environment: Environment(testContext.environment)
            )
        )
        
        let resultStream = ResultStreamImpl(
            dateProvider: dateProvider,
            logger: logger,
            testRunnerStream: testRunnerStream
        )
        let observableFileReader: ObservableFileReader = ObservableFileReaderImpl(
            path: resultStreamFile,
            processControllerProvider: processControllerProvider
        )
        
        var observableFileReaderHandler: ObservableFileReaderHandler?
        
        processController.onStart { [logger] sender, _ in
            testRunnerStream.openStream()
            do {
                observableFileReaderHandler = try observableFileReader.read(handler: resultStream.write(data:))
            } catch {
                logger.error("Failed to read stream file: \(error)", subprocessPidInfo: sender.subprocessInfo.pidInfo)
                return sender.terminateAndForceKillIfNeeded()
            }
            resultStream.streamContents { error in
                if let error = error {
                    logger.error("Result stream error: \(error)", subprocessPidInfo: sender.subprocessInfo.pidInfo)
                }
                testRunnerStream.closeStream()
            }
        }
        processController.onTermination { _, _ in
            observableFileReaderHandler?.cancel()
            resultStream.close()
        }
        return ProcessControllerWrappingTestRunnerInvocation(
            processController: processController
        )
    }
    
    public func additionalEnvironment(absolutePath: AbsolutePath) -> [String: String] {
        return ["EMCEE_XCRESULT_PATH": absolutePath.pathString.appending("/resultBundle.xcresult")]
    }
}
