import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import Foundation
import Logging
import Models
import ProcessController
import ResourceLocationResolver
import Runner
import RunnerModels
import SimulatorPoolModels
import TemporaryStuff

public final class XcodebuildBasedTestRunner: TestRunner {
    private let xctestJsonLocation: XCTestJsonLocation?
    private let dateProvider: DateProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    
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
                    .directlyAccessibleResourcePath()
            ]
        } else {
            xcodebuildLogParser = try RegexLogParser(dateProvider: dateProvider)
            insertedLibraries = []
        }
        
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
                environment: testContext.environment
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
        
        return ProcessControllerWrappingTestRunnerInvocation(processController: processController)
    }
}
