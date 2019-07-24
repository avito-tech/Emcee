import Foundation
import Models
import ProcessController
import ResourceLocationResolver
import SimulatorPool
import fbxctest

public final class FbxctestBasedTestRunner {
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorSettings: SimulatorSettings
    
    public init(
        resourceLocationResolver: ResourceLocationResolver,
        simulatorSettings: SimulatorSettings
    ) {
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorSettings = simulatorSettings
    }
    
    public func run(
        buildArtifacts: BuildArtifacts,
        entriesToRun: [TestEntry],
        fbxctestLocation: FbxctestLocation,
        maximumAllowedSilenceDuration: TimeInterval,
        singleTestMaximumDuration: TimeInterval,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream,
        testType: TestType
    ) throws -> StandardStreamsCaptureConfig {
        let fbxctestOutputProcessor = try FbxctestOutputProcessor(
            subprocess: Subprocess(
                arguments: try fbxctestArguments(
                    buildArtifacts: buildArtifacts,
                    entriesToRun: entriesToRun,
                    fbxctestLocation: fbxctestLocation,
                    testDestination: testContext.testDestination,
                    testType: testType
                ),
                environment: testContext.environment,
                silenceBehavior: SilenceBehavior(
                    automaticAction: .noAutomaticAction,
                    allowedSilenceDuration: maximumAllowedSilenceDuration
                )
            ),
            simulatorId: testContext.simulatorInfo.simulatorUuid?.uuidString ?? "unknown_uuid",
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
        testDestination: TestDestination,
        testType: TestType
    ) throws -> [SubprocessArgument] {
        let resolvableFbxctest = resourceLocationResolver.resolvable(withRepresentable: fbxctestLocation)
        
        var arguments: [SubprocessArgument] = [
            resolvableFbxctest.asArgumentWith(packageName: PackageName.fbxctest),
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
        return arguments
    }
}

private extension TestType {
    var asArgument: SubprocessArgument {
        return "-" + self.rawValue
    }
}
