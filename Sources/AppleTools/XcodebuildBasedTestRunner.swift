import BuildArtifacts
import CommonTestModels
import DateProvider
import DeveloperDirLocator
import EmceeLogging
import FileSystem
import Foundation
import MetricsExtensions
import ObservableFileReader
import ProcessController
import QueueModels
import ResourceLocationResolver
import ResultStream
import ResultStreamModels
import Runner
import RunnerModels
import Tmp
import PathLib
import XcodebuildTestRunnerConstants
import Zip

public final class XcodebuildBasedTestRunner: TestRunner {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let host: String
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let version: Version
    private let xcResultTool: XcResultTool
    private let zipCompressor: ZipCompressor
    
    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        host: String,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        version: Version,
        xcResultTool: XcResultTool,
        zipCompressor: ZipCompressor
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.host = host
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.version = version
        self.xcResultTool = xcResultTool
        self.zipCompressor = zipCompressor
    }
    
    public func prepareTestRun(
        buildArtifacts: AppleBuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        logger: ContextualLogger,
        specificMetricRecorder: SpecificMetricRecorder,
        testContext: AppleTestContext,
        testRunnerStream: TestRunnerStream,
        zippedResultBundleOutputPath: AbsolutePath?
    ) throws -> TestRunnerInvocation {
        let resultStreamFile = testContext.testRunnerWorkingDirectory.resultStreamPath
        try fileSystem.createFile(path: resultStreamFile, data: nil)
        
        let xcresultBundlePath = testContext.testRunnerWorkingDirectory.xcresultBundlePath
        
        let xcTestRunFile = XcTestRunFileArgument(
            buildArtifacts: buildArtifacts,
            entriesToRun: entriesToRun,
            path: testContext.testRunnerWorkingDirectory.xctestRunPath,
            resourceLocationResolver: resourceLocationResolver,
            testContext: testContext,
            testingEnvironment: XcTestRunTestingEnvironment(
                insertedLibraries: testContext.userInsertedLibraries
            )
        )
        
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "xcodebuild",
                    "-destination", XcodebuildSimulatorDestinationArgument(destinationId: testContext.simulator.udid),
                    "-derivedDataPath", testContext.testRunnerWorkingDirectory.derivedDataPath,
                    "-resultBundlePath", xcresultBundlePath,
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
            }
        }
        processController.onTermination { [weak self] _, _ in
            observableFileReaderHandler?.cancel()
            resultStream.close()
            
            if let strongSelf = self {
                strongSelf.readResultBundle(
                    logger: logger,
                    path: xcresultBundlePath,
                    specificMetricRecorder: specificMetricRecorder,
                    testRunnerStream: testRunnerStream,
                    zippedResultBundleOutputPath: zippedResultBundleOutputPath
                )
            }

            testRunnerStream.closeStream()
        }
        return ProcessControllerWrappingTestRunnerInvocation(
            processController: processController,
            logger: logger
        )
    }
    
    public func additionalEnvironment(testRunnerWorkingDirectory: TestRunnerWorkingDirectory) -> [String: String] {
        return [
            XcodebuildTestRunnerConstants.envXcresultPath: testRunnerWorkingDirectory.xcresultBundlePath.pathString
        ]
    }
    
    private func readResultBundle(
        logger: ContextualLogger,
        path: AbsolutePath,
        specificMetricRecorder: SpecificMetricRecorder,
        testRunnerStream: TestRunnerStream,
        zippedResultBundleOutputPath: AbsolutePath?
    ) {
        do {
            let actionsInvocationRecord = try xcResultTool.get(path: path)
            actionsInvocationRecord.issues.testFailureSummaries?.values.forEach { (testFailureIssueSummary: RSTestFailureIssueSummary) in
                testRunnerStream.caughtException(
                    testException: testFailureIssueSummary.testException()
                )
            }
            
            if let zippedResultBundleOutputPath = zippedResultBundleOutputPath {
                do {
                    _ = try zipCompressor.createArchive(
                        archivePath: zippedResultBundleOutputPath,
                        workingDirectory: path.removingLastComponent,
                        contentsToCompress: RelativePath(
                            components: [path.lastComponent]
                        )
                    )
                } catch {
                    logger.error("Error zipping xcresult bundle at \(path): \(error)")
                }
            }
        } catch {
            logger.error("Error parsing xcresult bundle at \(path): \(error)")
            specificMetricRecorder.capture(
                CorruptedXcresultBundleMetric(
                    host: host,
                    version: version,
                    timestamp: dateProvider.currentDate()
                )
            )
            testRunnerStream.caughtException(
                testException: TestException(
                    reason: "Error parsing xcresult bundle: \(error)",
                    filePathInProject: path.pathString,
                    lineNumber: 0,
                    relatedTestName: nil
                )
            )
        }
    }
}
