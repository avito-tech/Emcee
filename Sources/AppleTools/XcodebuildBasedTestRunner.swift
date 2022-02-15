import BuildArtifacts
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

public final class XcodebuildBasedTestRunner: TestRunner {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let host: String
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let version: Version
    private let xcResultTool: XcResultTool
    
    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        host: String,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        version: Version,
        xcResultTool: XcResultTool
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.host = host
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.version = version
        self.xcResultTool = xcResultTool
    }
    
    public func prepareTestRun(
        buildArtifacts: AppleBuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        logger: ContextualLogger,
        specificMetricRecorder: SpecificMetricRecorder,
        testContext: AppleTestContext,
        testRunnerStream: TestRunnerStream
    ) throws -> TestRunnerInvocation {
        let resultStreamFile = testContext.testRunnerWorkingDirectory.appending("result_stream.json")
        try fileSystem.createFile(path: resultStreamFile, data: nil)
        
        let xcresultBundlePath = self.xcresultBundlePath(
            testRunnerWorkingDirectory: testContext.testRunnerWorkingDirectory
        )
        
        let xcTestRunFile = XcTestRunFileArgument(
            buildArtifacts: buildArtifacts,
            entriesToRun: entriesToRun,
            path: testContext.testRunnerWorkingDirectory.appending("testrun.xctestrun"),
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
                    "-derivedDataPath", testContext.testRunnerWorkingDirectory.appending("derivedData"),
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
                    testRunnerStream: testRunnerStream
                )
            }

            testRunnerStream.closeStream()
        }
        return ProcessControllerWrappingTestRunnerInvocation(
            processController: processController,
            logger: logger
        )
    }
    
    public func additionalEnvironment(testRunnerWorkingDirectory: AbsolutePath) -> [String: String] {
        return [
            XcodebuildTestRunnerConstants.envXcresultPath: xcresultBundlePath(testRunnerWorkingDirectory: testRunnerWorkingDirectory).pathString
        ]
    }
    
    private func xcresultBundlePath(testRunnerWorkingDirectory: AbsolutePath) -> AbsolutePath {
        return testRunnerWorkingDirectory.appending("resultBundle.xcresult")
    }
    
    private func readResultBundle(
        logger: ContextualLogger,
        path: AbsolutePath,
        specificMetricRecorder: SpecificMetricRecorder,
        testRunnerStream: TestRunnerStream
    ) {
        do {
            let actionsInvocationRecord = try xcResultTool.get(path: path)
            actionsInvocationRecord.issues.testFailureSummaries?.values.forEach{ (testFailureIssueSummary: RSTestFailureIssueSummary) in
                testRunnerStream.caughtException(
                    testException: testFailureIssueSummary.testException()
                )
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
