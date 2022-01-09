import ArgLib
import AutomaticTermination
import BuildArtifacts
import Deployer
import EmceeDI
import EmceeVersion
import Foundation
import MetricsExtensions
import PathLib
import QueueModels
import QueueServerConfiguration
import RunnerModels
import ScheduleStrategy
import SimulatorPoolModels
import TestArgFile
import Tmp
import UniqueIdentifierGenerator
import LocalQueueServerRunner
import RESTServer

public final class RunTestsCommand: Command {
    public let name = "runTests"
    public let description = "Runs tests (easy to use command)"
    public let arguments: Arguments = [
        ArgumentDescriptions.queue.asRequired.asMultiple,
        ArgumentDescriptions.worker.asRequired.asMultiple,
        ArgumentDescriptions.device.asRequired,
        ArgumentDescriptions.runtime.asRequired,
        ArgumentDescriptions.testBundle.asRequired,
        ArgumentDescriptions.app.asOptional,
        ArgumentDescriptions.runner.asOptional,
        ArgumentDescriptions.test.asOptional,
        ArgumentDescriptions.retries.asOptional,
        ArgumentDescriptions.testTimeout.asOptional,
    ]
    
    private let di: DI
    private let httpRestServer: HTTPRESTServer
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(di: DI) throws {
        self.di = di
        self.httpRestServer = HTTPRESTServer(
            automaticTerminationController: StayAliveTerminationController(),
            logger: try di.get(),
            portProvider: AnyAvailablePortProvider(),
            useOnlyIPv4: true
        )
        self.uniqueIdentifierGenerator = try di.get()
    }
    
    public func run(payload: CommandPayload) throws {
        let queueUrls: [URL] = try payload.nonEmptyCollectionOfValues(argumentName: ArgumentDescriptions.queue.name)
        let queueDeploymentDestinations = try queueUrls.map { try $0.deploymentDestination() }
        
        let workerUrls: [URL] = try payload.nonEmptyCollectionOfValues(argumentName: ArgumentDescriptions.worker.name)
        let workerDeploymentDestinations = try workerUrls.map { try $0.deploymentDestination() }
        
        let testBundlePath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testBundle.name)
        let xcTestBundle = XcTestBundle(location: TestBundleLocation(.localFilePath(testBundlePath.pathString)), testDiscoveryMode: .parseFunctionSymbols)
        
        let appBundlePath: AbsolutePath? = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.app.name)
        let runnerBundlePath: AbsolutePath? = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.runner.name)
        
        let buildArtifacts: BuildArtifacts
        if let runnerBundlePath = runnerBundlePath, let appBundlePath = appBundlePath {
            buildArtifacts = .iosUiTests(
                xcTestBundle: xcTestBundle,
                appBundle: AppBundleLocation(.localFilePath(appBundlePath.pathString)),
                runner: RunnerAppLocation(.localFilePath(runnerBundlePath.pathString)),
                additionalApplicationBundles: []
            )
        } else if let appBundlePath = appBundlePath {
            buildArtifacts = .iosApplicationTests(
                xcTestBundle: xcTestBundle,
                appBundle: AppBundleLocation(.localFilePath(appBundlePath.pathString))
            )
        } else {
            buildArtifacts = .iosLogicTests(xcTestBundle: xcTestBundle)
        }
        
        let testNamesToRun: [TestName] = try payload.possiblyEmptyCollectionOfValues(argumentName: ArgumentDescriptions.test.name)
        let numberOfRetries: UInt = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.retries.name) ?? TestArgFileDefaultValues.numberOfRetries
        let testTimeout: TimeInterval = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.testTimeout.name) ?? TestArgFileDefaultValues.testTimeoutConfiguration.singleTestMaximumDuration
        let testDestination = try TestDestination(
            deviceType: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.device.name),
            runtime: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.runtime.name)
        )
        
        var testsToRun: [TestToRun] = []
        if testNamesToRun.isEmpty {
            testsToRun = [.allDiscoveredTests]
        } else {
            testsToRun = testNamesToRun.map { .testName($0) }
        }
        
        var environment = [String: String]()
        ProcessInfo.processInfo.environment.forEach { (key: String, value: String) in
            if key.starts(with: "EMCEE_") {
                environment[String(key.dropFirst("EMCEE_".count))] = value
            }
        }
        
        let testArgFile = TestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: buildArtifacts,
                    developerDir: TestArgFileDefaultValues.developerDir,
                    environment: environment,
                    userInsertedLibraries: [],
                    numberOfRetries: numberOfRetries,
                    testRetryMode: TestArgFileDefaultValues.testRetryMode,
                    logCapturingMode: TestArgFileDefaultValues.logCapturingMode,
                    runnerWasteCleanupPolicy: TestArgFileDefaultValues.runnerWasteCleanupPolicy,
                    pluginLocations: [],
                    scheduleStrategy: TestArgFileDefaultValues.scheduleStrategy,
                    simulatorOperationTimeouts: TestArgFileDefaultValues.simulatorOperationTimeouts,
                    simulatorSettings: TestArgFileDefaultValues.simulatorSettings,
                    testDestination: testDestination,
                    testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: testTimeout, testRunnerMaximumSilenceDuration: testTimeout),
                    testsToRun: testsToRun,
                    workerCapabilityRequirements: TestArgFileDefaultValues.workerCapabilityRequirements
                )
            ],
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: AnalyticsConfiguration(),
                jobGroupId: JobGroupId(uniqueIdentifierGenerator.generate()),
                jobGroupPriority: .medium,
                jobId: JobId("autoJobId_" + uniqueIdentifierGenerator.generate()),
                jobPriority: .medium
            ),
            testDestinationConfigurations: []
        )
        
        let queueServerConfiguration = QueueServerConfiguration(
            globalAnalyticsConfiguration: AnalyticsConfiguration(),
            checkAgainTimeInterval: QueueServerConfigurationDefaultValues.checkAgainTimeInterval,
            queueServerDeploymentDestinations: queueDeploymentDestinations,
            queueServerTerminationPolicy: QueueServerConfigurationDefaultValues.queueServerTerminationPolicy,
            workerDeploymentDestinations: workerDeploymentDestinations,
            defaultWorkerSpecificConfiguration: QueueServerConfigurationDefaultValues.defaultWorkerConfiguration,
            workerSpecificConfigurations: [:],
            workerStartMode: QueueServerConfigurationDefaultValues.workerStartMode,
            useOnlyIPv4: QueueServerConfigurationDefaultValues.useOnlyIPv4
        )
        
        try RunTestsOnRemoteQueueLogic(di: di).run(
            commonReportOutput: ReportOutput(junit: nil, tracingReport: nil),
            emceeVersion: EmceeVersion.version,
            logger: try di.get(),
            queueServerConfiguration: queueServerConfiguration,
            remoteCacheConfig: nil,
            tempFolder: try TemporaryFolder(),
            testArgFile: testArgFile,
            httpRestServer: httpRestServer
        )
    }
}

extension TestName: ParsableArgument {
    public init(argumentValue: String) throws {
        self = try Self.createFromTestNameString(stringValue: argumentValue)
    }
}

extension Double: ParsableArgument {
    public init(argumentValue: String) throws {
        guard let value = Self(argumentValue) else {
            throw GenericParseError<Self>(argumentValue: argumentValue)
        }
        self = value
    }
}
