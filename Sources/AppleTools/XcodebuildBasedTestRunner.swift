import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import Foundation
import Logging
import ObservableFileReader
import ProcessController
import ResourceLocationResolver
import ResultStream
import Runner
import RunnerModels
import SimulatorPoolModels
import Tmp

public final class XcodebuildBasedTestRunner: TestRunner {
    private let xctestJsonLocation: XCTestJsonLocation?
    private let dateProvider: DateProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    
    public static let useResultStreamToggleEnvName = "EMCEE_USE_RESULT_STREAM"
    
    public init(
        xctestJsonLocation: XCTestJsonLocation?,
        dateProvider: DateProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.xctestJsonLocation = xctestJsonLocation
        self.dateProvider = dateProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func prepareTestRun(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        entriesToRun: [TestEntry],
        simulator: Simulator,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> TestRunnerInvocation {
        let xcodebuildLogParser: XcodebuildLogParser
        let insertedLibraries: [String]
        
        if let xctestJsonLocation = xctestJsonLocation {
            xcodebuildLogParser = XCTestJsonParser(dateProvider: dateProvider)
            insertedLibraries = [
                try resourceLocationResolver
                    .resolvePath(resourceLocation: xctestJsonLocation.resourceLocation)
                    .directlyAccessibleResourcePath().pathString
            ]
        } else {
            xcodebuildLogParser = try RegexLogParser(dateProvider: dateProvider)
            insertedLibraries = []
        }
        
        let invocationPath = try temporaryFolder.pathByCreatingDirectories(components: [testContext.contextUuid.uuidString])
        let resultStreamFile = try temporaryFolder.createFile(components: [testContext.contextUuid.uuidString], filename: "result_stream.json")
        
        let processController = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: [
                    "/usr/bin/xcrun",
                    "xcodebuild",
                    "-destination", XcodebuildSimulatorDestinationArgument(
                        destinationId: simulator.udid
                    ),
                    "-derivedDataPath", invocationPath.appending(component: "derivedData"),
                    "-resultBundlePath", invocationPath.appending(component: "resultBundle"),
                    "-resultStreamPath", resultStreamFile,
                    "-xctestrun", XcTestRunFileArgument(
                        buildArtifacts: buildArtifacts,
                        entriesToRun: entriesToRun,
                        resourceLocationResolver: resourceLocationResolver,
                        temporaryFolder: temporaryFolder,
                        testContext: testContext,
                        testType: testType,
                        testingEnvironment: XcTestRunTestingEnvironment(
                            insertedLibraries: insertedLibraries
                        )
                    ),
                    "-parallel-testing-enabled", "NO",
                    "test-without-building",
                ],
                environment: Environment(testContext.environment)
            )
        )
        
        let useResultStream = testContext.environment[Self.useResultStreamToggleEnvName] == "true"
        
        let xcodebuildOutputProcessor = XcodebuildOutputProcessor(
            testRunnerStream: testRunnerStream,
            xcodebuildLogParser: xcodebuildLogParser
        )
        let resultStream = ResultStreamImpl(
            dateProvider: dateProvider,
            testRunnerStream: testRunnerStream
        )
        let observableFileReader = try ObservableFileReaderImpl(
            path: resultStreamFile,
            processControllerProvider: processControllerProvider
        )
        var observableFileReaderHandler: ObservableFileReaderHandler?
        
        processController.onStart { sender, _ in
            testRunnerStream.openStream()
            
            if useResultStream {
                do {
                    observableFileReaderHandler = try observableFileReader.read(handler: resultStream.write(data:))
                } catch {
                    Logger.error("Failed to read stream file: \(error)")
                    return sender.terminateAndForceKillIfNeeded()
                }
                resultStream.streamContents { error in
                    if let error = error {
                        Logger.error("Result stream error: \(error)")
                    }
                    testRunnerStream.closeStream()
                }
            }
        }
        if !useResultStream {
            processController.onStdout { _, data, _ in
                xcodebuildOutputProcessor.newStdout(data: data)
            }
        }
        processController.onTermination { _, _ in
            if useResultStream {
                observableFileReaderHandler?.cancel()
                resultStream.close()
            } else {
                testRunnerStream.closeStream()
            }
        }
        return ProcessControllerWrappingTestRunnerInvocation(
            processController: processController
        )
    }
}
