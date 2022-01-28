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
import OSLog

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
        buildArtifacts: IosBuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        logger: ContextualLogger,
        specificMetricRecorder: SpecificMetricRecorder,
        testContext: TestContext,
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
                    "-destination", XcodebuildSimulatorDestinationArgument(destinationId: testContext.simulatorUdid),
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
        
        let uuid = UUID().uuidString
        
        processController.onStart { [logger] sender, _ in
            testRunnerStream.openStream()
            do {
                observableFileReaderHandler = try observableFileReader.read(handler: resultStream.write(data:))
            } catch {
                logger.error("Failed to read stream file: \(error)", subprocessPidInfo: sender.subprocessInfo.pidInfo)
                return sender.terminateAndForceKillIfNeeded()
            }
            resultStream.streamContents { [weak self] error in
                if let error = error {
                    logger.error("Result stream error: \(error)", subprocessPidInfo: sender.subprocessInfo.pidInfo)
                }
                
                self?.osLogger.debug("\(uuid, privacy: .public) - Stream contents completion")
                if let strongSelf = self {
                    strongSelf.readResultBundle(
                        path: xcresultBundlePath,
                        specificMetricRecorder: specificMetricRecorder,
                        testRunnerStream: testRunnerStream,
                        uuid: uuid
                    )
                }

                testRunnerStream.closeStream()
            }
        }
        processController.onTermination { [weak self] _, _ in
            observableFileReaderHandler?.cancel()
            resultStream.close()
            self?.osLogger.debug("\(uuid, privacy: .public) - Result stream is closed")
            
//            if let strongSelf = self {
//                strongSelf.readResultBundle(
//                    path: xcresultBundlePath,
//                    specificMetricRecorder: specificMetricRecorder,
//                    testRunnerStream: testRunnerStream
//                )
//            }
//
//            testRunnerStream.closeStream()
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
        return testRunnerWorkingDirectory.appending("resultBundle.xcresult")
    }
    
    let osLogger = Logger(subsystem: "ru.avito.emcee", category: "ResultBundle")
    
    private func readResultBundle(
        path: AbsolutePath,
        specificMetricRecorder: SpecificMetricRecorder,
        testRunnerStream: TestRunnerStream,
        uuid: String
    ) {
        
        do {
//            try! FileManager.default.copyItem(
//                atPath: path.pathString,
//                toPath: "/Users/tssolonin/Desktop/bundles/normal_\(path.basename)_\(CFAbsoluteTimeGetCurrent())_\(ProcessInfo.processInfo.processIdentifier)_\(UUID().uuidString).xcresult"
//            )
            
            let actionsInvocationRecord = try xcResultTool.get(path: path)
            actionsInvocationRecord.issues.testFailureSummaries?.values.forEach{ (testFailureIssueSummary: RSTestFailureIssueSummary) in
                testRunnerStream.caughtException(
                    testException: testFailureIssueSummary.testException()
                )
            }
            
            osLogger.debug("\(uuid, privacy: .public) - Parsed bundle")
        } catch {
//            try! FileManager.default.copyItem(
//                atPath: path.pathString,
//                toPath: "/Users/tssolonin/Desktop/bundles/\(path.basename)_\(CFAbsoluteTimeGetCurrent())_\(ProcessInfo.processInfo.processIdentifier)_\(UUID().uuidString).xcresult"
//            )
            
            osLogger.debug("\(uuid, privacy: .public) - Failed to parse bundle")
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
