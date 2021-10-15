import ArgLib
import BuildArtifacts
import DeveloperDirModels
import EmceeLogging
import Foundation
import DI
import MetricsExtensions
import PathLib
import PluginSupport
import QueueModels
import RunnerModels
import ScheduleStrategy
import SocketModels
import SimulatorPoolModels
import TestArgFile
import WorkerCapabilities
import WorkerCapabilitiesModels

public final class InitArgFileCommand: Command {
    public let name = "initArgFile"
    public let description = "Inits example test arg file"
    public let arguments: Arguments = [
        ArgumentDescriptions.output.asRequired,
    ]
    
    private let logger: ContextualLogger
    
    public init(
        di: DI
    ) throws {
        self.logger = try di.get()
    }
    
    public func run(payload: CommandPayload) throws {
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)
        
        let testDestination = try TestDestination(deviceType: "iPhone X", runtime: "15.1")
        
        let testArgFile = TestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: BuildArtifacts(
                        appBundle: AppBundleLocation(
                            .remoteUrl(URL(string: "http://example.com/__some_build_id_to_avoid_artifacts_clash__/MyApp.zip#path/to/MyApp.app")!, nil)
                        ),
                        runner: nil,
                        xcTestBundle: XcTestBundle(
                            location: TestBundleLocation(
                                .remoteUrl(URL(string: "http://example.com/__some_build_id_to_avoid_artifacts_clash__/UnitTests.zip#UnitTests.xctest")!, nil)
                            ),
                            testDiscoveryMode: .parseFunctionSymbols
                        ),
                        additionalApplicationBundles: [
                            AdditionalAppBundleLocation(.remoteUrl(URL(string: "http://example.com/__some_build_id_to_avoid_artifacts_clash__/AdditionalApp.zip#AdiitionalApp.app")!, ["X-Some-Header": "SomeValueOfHeader"]))
                        ]
                    ),
                    developerDir: DeveloperDir.useXcode(
                        CFBundleShortVersionString: "13.1"
                    ),
                    environment: [
                        "SomeEnvName": "These envs will be available from tests",
                    ],
                    numberOfRetries: 0,
                    pluginLocations: [
                        PluginLocation(.remoteUrl(URL(string: "http://example.com/__some_build_id_to_avoid_artifacts_clash__/MyPlugin.zip#MyPlugin.emceeplugin")!, nil)),
                    ],
                    scheduleStrategy: TestArgFileDefaultValues.scheduleStrategy,
                    simulatorControlTool: TestArgFileDefaultValues.simulatorControlTool,
                    simulatorOperationTimeouts: SimulatorOperationTimeouts(
                        create: 60,
                        boot: 180,
                        delete: 30,
                        shutdown: 30,
                        automaticSimulatorShutdown: 600,
                        automaticSimulatorDelete: 200
                    ),
                    simulatorSettings: TestArgFileDefaultValues.simulatorSettings,
                    testDestination: testDestination,
                    testRunnerTool: TestArgFileDefaultValues.testRunnerTool,
                    testTimeoutConfiguration: TestArgFileDefaultValues.testTimeoutConfiguration,
                    testType: .uiTest,
                    testsToRun: [
                        .testName(TestName(className: "ClassName", methodName: "testSpecificTestMethodName")),
                        .testName(TestName(className: "ClassName", methodName: "testSpecificTestMethodName__youCanRepeatTestNames")),
                        .testName(TestName(className: "ClassName", methodName: "testSpecificTestMethodName__youCanRepeatTestNames")),
                        .allDiscoveredTests,
                    ],
                    workerCapabilityRequirements: [
                        WorkerCapabilityRequirement(
                            capabilityName: XcodeCapabilitiesProvider.workerCapabilityName(shortVersion: "13.0"),
                            constraint: .present
                        )
                    ]
                )
            ],
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: AnalyticsConfiguration(
                    graphiteConfiguration: MetricConfiguration(
                        socketAddress: SocketAddress(
                            host: "graphite.example.com",
                            port: 42
                        ),
                        metricPrefix: "some.prefix.for.emcee"
                    ),
                    statsdConfiguration: MetricConfiguration(
                        socketAddress: SocketAddress(host: "statsd.example.com", port: 1234),
                        metricPrefix: "some.prefix.for.emcee"
                    ),
                    kibanaConfiguration: KibanaConfiguration(
                        endpoints: [
                            URL(string: "http://kibana.example.com:12345/")!,
                        ],
                        indexPattern: "emcee-index-16112021-"
                    ),
                    persistentMetricsJobId: "UnitTests",
                    metadata: [
                        "ciPullRequestId": "12345",
                        "ciBranchName": "SomeBranchNameWhereTestsAreRunning",
                    ]
                ),
                jobGroupId: JobGroupId("SomeGroupIdForMultipleJobsGrouping_eg_UUID_or_PR12345"),
                jobGroupPriority: Priority(750),
                jobId: JobId("ThisJobId_eg_UUID_or_PR12345_UnitTests"),
                jobPriority: .medium
            ),
            testDestinationConfigurations: [
                TestDestinationConfiguration(
                    testDestination: testDestination,
                    reportOutput: ReportOutput(
                        junit: "/where/to/store/junit/for/\(testDestination.deviceType)/\(testDestination.runtime)/junit.xml",
                        tracingReport: "/where/to/store/trace/for/\(testDestination.deviceType)/\(testDestination.runtime)/chromium.trace"
                    )
                ),
            ]
        )
        
        let data = try JSONEncoder.pretty().encode(testArgFile)
        try data.write(to: outputPath.fileUrl)
        
        logger.info("Generated test arg file stored at \(outputPath)")
    }
}
