import BuildArtifacts
import DeveloperDirLocator
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import ResourceLocationResolver
import Runner
import RunnerModels
import SimulatorPoolModels
import TemporaryStuff

public final class FbxctestBasedTestRunner: TestRunner {
    private let encoder = JSONEncoder()
    private let fbxctestLocation: FbxctestLocation
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        fbxctestLocation: FbxctestLocation,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.fbxctestLocation = fbxctestLocation
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
        let folderStack = try temporaryFolder.pathByCreatingDirectories(components: ["fbxctest_working_dir", UUID().uuidString, "fbxctest_tmp"])
        let fbxctestWorkingDirectory = folderStack.removingLastComponent
        let fbxctestTempFolder = folderStack
        defer { cleanUp(fbxctestWorkingDirectory: fbxctestWorkingDirectory) }
        
        let fbxctestOutputProcessor = try FbxctestOutputProcessor(
            onTestStarted: { testName in testRunnerStream.testStarted(testName: testName) },
            onTestStopped: { testStoppedEvent in testRunnerStream.testStopped(testStoppedEvent: testStoppedEvent) },
            processController: try processControllerProvider.createProcessController(
                subprocess: Subprocess(
                    arguments: try fbxctestArguments(
                        buildArtifacts: buildArtifacts,
                        entriesToRun: entriesToRun,
                        fbxctestLocation: fbxctestLocation,
                        fbxctestWorkingDirectory: fbxctestWorkingDirectory,
                        simulator: simulator,
                        testDestination: testContext.testDestination,
                        testType: testType
                    ),
                    environment: fbxctestEnvironment(
                        testContext: testContext,
                        fbxctestTempFolder: fbxctestTempFolder
                    )
                )
            )
        )
        return fbxctestOutputProcessor
    }

    private func fbxctestArguments(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        fbxctestLocation: FbxctestLocation,
        fbxctestWorkingDirectory: AbsolutePath,
        simulator: Simulator,
        testDestination: TestDestination,
        testType: TestType
    ) throws -> [SubprocessArgument] {
        let resolvableFbxctest = resourceLocationResolver.resolvable(withRepresentable: fbxctestLocation)
        
        var arguments: [SubprocessArgument] = [
            resolvableFbxctest.asArgumentWith(implicitFilenameInArchive: "fbxctest"),
             "-destination", testDestination.fbxctestDestinationString,
             testType.asArgument
        ]
        
        let resolvableXcTestBundle = resourceLocationResolver.resolvable(withRepresentable: buildArtifacts.xcTestBundle.location)
        
        switch testType {
        case .logicTest:
            arguments += [resolvableXcTestBundle.asArgument()]
        case .appTest:
            guard let representableAppBundle = buildArtifacts.appBundle else {
                throw RunnerError.noAppBundleDefinedForUiOrApplicationTesting
            }
            arguments += [
                JoinedSubprocessArgument(
                    components: [
                        resolvableXcTestBundle.asArgument(),
                        resourceLocationResolver.resolvable(withRepresentable: representableAppBundle).asArgument()
                    ],
                    separator: ":")]
        case .uiTest:
            guard let representableAppBundle = buildArtifacts.appBundle else {
                throw RunnerError.noAppBundleDefinedForUiOrApplicationTesting
            }
            guard let representableRunnerBundle = buildArtifacts.runner else {
                throw RunnerError.noRunnerAppDefinedForUiTesting
            }
            let resolvableAdditionalAppBundles = buildArtifacts.additionalApplicationBundles
                .map { resourceLocationResolver.resolvable(withRepresentable: $0) }
            let components = ([
                resolvableXcTestBundle,
                resourceLocationResolver.resolvable(withRepresentable: representableRunnerBundle),
                resourceLocationResolver.resolvable(withRepresentable: representableAppBundle)
                ] + resolvableAdditionalAppBundles).map { $0.asArgument() }
            arguments += [JoinedSubprocessArgument(components: components, separator: ":")]
        }
        
        arguments += entriesToRun.flatMap {
            [
                "-only",
                JoinedSubprocessArgument(
                    components: [resolvableXcTestBundle.asArgument(), $0.testName.stringValue],
                    separator: ":"
                )
            ]
        }
        arguments += ["run-tests", "-sdk", "iphonesimulator"]

        arguments += ["-keep-simulators-alive"]
        
        arguments += ["-simulatorSetPath", simulator.simulatorSetPath.pathString]
        arguments += ["-workingDirectory", fbxctestWorkingDirectory.pathString]
        return arguments
    }
    
    private func fbxctestEnvironment(
        testContext: TestContext,
        fbxctestTempFolder: AbsolutePath
    ) -> [String: String] {
        var result = testContext.environment
        result["TMPDIR"] = fbxctestTempFolder.pathString
        return result
    }
    
    private func cleanUp(fbxctestWorkingDirectory: AbsolutePath) {
        do {
            try FileManager.default.removeItem(atPath: fbxctestWorkingDirectory.pathString)
        } catch {
            Logger.warning("Failed to remove fbxctest working directory \(fbxctestWorkingDirectory): \(error)")
        }
    }
}

private extension TestType {
    var asArgument: SubprocessArgument {
        return "-" + self.rawValue
    }
}

private extension TestDestination {
    var fbxctestDestinationString: String {
        return "name=\(deviceType),OS=iOS \(runtime)"
    }
}
