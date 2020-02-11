import DeveloperDirLocator
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import ResourceLocationResolver
import Runner
import SimulatorPool
import TemporaryStuff

public final class FbxctestBasedTestRunner: TestRunner {
    private let fbxctestLocation: FbxctestLocation
    private let resourceLocationResolver: ResourceLocationResolver
    private let encoder = JSONEncoder()
    
    public init(
        fbxctestLocation: FbxctestLocation,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.fbxctestLocation = fbxctestLocation
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
        return try standardStreamsCaptureConfigOfFbxctestProcess(
            buildArtifacts: buildArtifacts,
            entriesToRun: entriesToRun,
            simulator: simulator,
            simulatorSettings: simulatorSettings,
            temporaryFolder: temporaryFolder,
            testContext: testContext,
            testRunnerStream: testRunnerStream,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testType: testType
        )
    }
    
    private func standardStreamsCaptureConfigOfFbxctestProcess(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        simulator: Simulator,
        simulatorSettings: SimulatorSettings,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig {
        let folderStack = try temporaryFolder.pathByCreatingDirectories(components: ["fbxctest_working_dir", UUID().uuidString, "fbxctest_tmp"])
        let fbxctestWorkingDirectory = folderStack.removingLastComponent
        let fbxctestTempFolder = folderStack
        defer { cleanUp(fbxctestWorkingDirectory: fbxctestWorkingDirectory) }
        
        let fbxctestOutputProcessor = try FbxctestOutputProcessor(
            subprocess: Subprocess(
                arguments: try fbxctestArguments(
                    buildArtifacts: buildArtifacts,
                    entriesToRun: entriesToRun,
                    fbxctestLocation: fbxctestLocation,
                    fbxctestWorkingDirectory: fbxctestWorkingDirectory,
                    simulator: simulator,
                    simulatorSettings: simulatorSettings,
                    testDestination: testContext.testDestination,
                    testType: testType
                ),
                environment: fbxctestEnvironment(
                    testContext: testContext,
                    fbxctestTempFolder: fbxctestTempFolder
                ),
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: testTimeoutConfiguration.testRunnerMaximumSilenceDuration
                )
            ),
            singleTestMaximumDuration: testTimeoutConfiguration.singleTestMaximumDuration,
            onTestStarted: { testName in testRunnerStream.testStarted(testName: testName) },
            onTestStopped: { testStoppedEvent in testRunnerStream.testStopped(testStoppedEvent: testStoppedEvent) }
        )
        fbxctestOutputProcessor.processOutputAndWaitForProcessTermination()
        return fbxctestOutputProcessor.subprocess.standardStreamsCaptureConfig
    }
    
    private func fbxctestArguments(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        fbxctestLocation: FbxctestLocation,
        fbxctestWorkingDirectory: AbsolutePath,
        simulator: Simulator,
        simulatorSettings: SimulatorSettings,
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
            
            let simulatorLocalizationFile = FbxctestSimulatorLocalizationFile(
                localeIdentifier: simulatorSettings.simulatorLocalizationSettings.localeIdentifier,
                keyboards: simulatorSettings.simulatorLocalizationSettings.keyboards,
                passcodeKeyboards: simulatorSettings.simulatorLocalizationSettings.passcodeKeyboards,
                languages: simulatorSettings.simulatorLocalizationSettings.languages,
                addingEmojiKeybordHandled: simulatorSettings.simulatorLocalizationSettings.addingEmojiKeybordHandled,
                enableKeyboardExpansion: simulatorSettings.simulatorLocalizationSettings.enableKeyboardExpansion,
                didShowInternationalInfoAlert: simulatorSettings.simulatorLocalizationSettings.didShowInternationalInfoAlert
            )
            let simulatorLocalizationFilePath = fbxctestWorkingDirectory.appending(component: "simulator_localization_settings.json")
            try encoder.encode(simulatorLocalizationFile).write(to: simulatorLocalizationFilePath.fileUrl)
            arguments += [
                "-simulator-localization-settings", simulatorLocalizationFilePath
            ]
            
            let watchdogFile = FbxctestWatchdogFile(
                bundleIds: simulatorSettings.watchdogSettings.bundleIds,
                timeout: simulatorSettings.watchdogSettings.timeout
            )
            let watchdogFilePath = fbxctestWorkingDirectory.appending(component: "watchdog_settings.json")
            try encoder.encode(watchdogFile).write(to: watchdogFilePath.fileUrl)
            arguments += [
                "-watchdog-settings", watchdogFilePath
            ]
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
