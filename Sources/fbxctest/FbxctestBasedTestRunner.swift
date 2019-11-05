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
    private let fbxctestSimFolderCreator = FbxctestSimFolderCreator()
    
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
        maximumAllowedSilenceDuration: TimeInterval,
        simulator: Simulator,
        simulatorSettings: SimulatorSettings,
        singleTestMaximumDuration: TimeInterval,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig {
        return try standardStreamsCaptureConfigOfFbxctestProcess(
            buildArtifacts: buildArtifacts,
            entriesToRun: entriesToRun,
            maximumAllowedSilenceDuration: maximumAllowedSilenceDuration,
            simulator: simulator,
            simulatorSettings: simulatorSettings,
            singleTestMaximumDuration: singleTestMaximumDuration,
            temporaryFolder: temporaryFolder,
            testContext: testContext,
            testRunnerStream: testRunnerStream,
            testType: testType
        )
    }
    
    private func standardStreamsCaptureConfigOfFbxctestProcess(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        maximumAllowedSilenceDuration: TimeInterval,
        simulator: Simulator,
        simulatorSettings: SimulatorSettings,
        singleTestMaximumDuration: TimeInterval,
        temporaryFolder: TemporaryFolder,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig {
        let simFolderPath = try fbxctestSimFolderCreator.createSimFolderForFbxctest(
            containerPath: try temporaryFolder.pathByCreatingDirectories(components: ["fbxctest_sim_env", UUID().uuidString]),
            simulatorPath: simulator.path
        )
        defer { deleteFbxctestSimulatorEnvironment(simFolderPath: simFolderPath) }
        
        let fbxctestOutputProcessor = try FbxctestOutputProcessor(
            subprocess: Subprocess(
                arguments: try fbxctestArguments(
                    buildArtifacts: buildArtifacts,
                    entriesToRun: entriesToRun,
                    fbxctestLocation: fbxctestLocation,
                    simFolderPath: simFolderPath,
                    simulator: simulator,
                    simulatorSettings: simulatorSettings,
                    testDestination: testContext.testDestination,
                    testType: testType
                ),
                environment: testContext.environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .interruptAndForceKill,
                    allowedSilenceDuration: maximumAllowedSilenceDuration
                )
            ),
            singleTestMaximumDuration: singleTestMaximumDuration,
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
        simFolderPath: AbsolutePath,
        simulator: Simulator,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testType: TestType
    ) throws -> [SubprocessArgument] {
        let resolvableFbxctest = resourceLocationResolver.resolvable(withRepresentable: fbxctestLocation)
        
        var arguments: [SubprocessArgument] = [
            resolvableFbxctest.asArgumentWith(implicitFilenameInArchive: "fbxctest"),
             "-destination", testDestination.destinationString,
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
            
            if let simulatorLocatizationSettings = simulatorSettings.simulatorLocalizationSettings {
                arguments += [
                    "-simulator-localization-settings",
                    resourceLocationResolver.resolvable(withRepresentable: simulatorLocatizationSettings).asArgument()
                ]
            }
            if let watchdogSettings = simulatorSettings.watchdogSettings {
                arguments += [
                    "-watchdog-settings",
                    resourceLocationResolver.resolvable(withRepresentable: watchdogSettings).asArgument()
                ]
            }
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
        
        arguments += ["-workingDirectory", simFolderPath]
        return arguments
    }
    
    private func deleteFbxctestSimulatorEnvironment(simFolderPath: AbsolutePath) {
        do {
            Logger.debug("Deleting sim folder: \(simFolderPath)")
            try FileManager.default.removeItem(atPath: simFolderPath.pathString)
        } catch {
            Logger.warning("Failed to delete sim folder \(simFolderPath): \(error). This error will be ignored.")
        }
    }
}

private extension TestType {
    var asArgument: SubprocessArgument {
        return "-" + self.rawValue
    }
}
