import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import FileSystem
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
import XcodebuildTestRunnerConstants

public final class XcodebuildBasedTestRunner: TestRunner {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
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
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> TestRunnerInvocation {
        let resultStreamFile = testContext.testRunnerWorkingDirectory.appending(component: "result_stream.json")
        try fileSystem.createFile(atPath: resultStreamFile, data: nil)
        
        let xcTestRunFile = XcTestRunFileArgument(
            buildArtifacts: buildArtifacts,
            entriesToRun: entriesToRun,
            path: testContext.testRunnerWorkingDirectory.appending(component: "testrun.xctestrun"),
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
                    "-derivedDataPath", testContext.testRunnerWorkingDirectory.appending(component: "derivedData"),
                    "-resultBundlePath", xcresultBundlePath(testRunnerWorkingDirectory: testContext.testRunnerWorkingDirectory),
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
    
    public func additionalEnvironment(testRunnerWorkingDirectory: AbsolutePath) -> [String: String] {
        return [
            XcodebuildTestRunnerConstants.envXcresultPath: xcresultBundlePath(testRunnerWorkingDirectory: testRunnerWorkingDirectory).pathString
        ]
    }
    
    private func xcresultBundlePath(testRunnerWorkingDirectory: AbsolutePath) -> AbsolutePath {
        return testRunnerWorkingDirectory.appending(component: "resultBundle.xcresult")
    }
}
