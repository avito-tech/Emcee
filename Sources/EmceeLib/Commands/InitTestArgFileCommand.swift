import ArgLib
import BuildArtifacts
import CommonTestModels
import DeveloperDirModels
import EmceeDI
import EmceeLogging
import Foundation
import MetricsExtensions
import PathLib
import PluginSupport
import QueueModels
import SimulatorPoolModels
import SocketModels
import TestArgFile
import TestDestination
import WorkerCapabilities
import WorkerCapabilitiesModels

public final class InitTestArgFileCommand: Command {
    public let name = "initTestArgFile"
    public let description = "Generates a sample test arg file"
    public let arguments: Arguments = [
        ArgumentDescriptions.output.asRequired,
    ]
    
    private let di: DI
    
    public init(
        di: DI
    ) throws {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let logger = try di.get(ContextualLogger.self)
        
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)
        
        let testDestination = TestDestination.iOSSimulator(deviceType: "iPhone X", version: "15.1")
        
        let testArgFile = TestArgFile(
            entries: [
                TestArgFileEntry(
                    buildArtifacts: AppleBuildArtifacts.iosUiTests(
                        xcTestBundle: XcTestBundle(
                            location: TestBundleLocation(
                                .remoteUrl(
                                    URL(string: "http://storage.example.com/build1234/FunctionalTests.zip#FunctionalTests.xctest")!,
                                    nil
                                )
                            ),
                            testDiscoveryMode: .parseFunctionSymbols
                        ),
                        appBundle: AppBundleLocation(
                            .remoteUrl(
                                URL(string: "http://storage.example.com/build1234/MainApp.zip#MainApp.app")!,
                                [
                                    "X-Header": "You can append arbitrary headers if needed, e.g. for auth",
                                    "X-Comment": "Also please read https://github.com/avito-tech/Emcee/wiki/URL-Handling",
                                ]
                            )
                        ),
                        runner: RunnerAppLocation(
                            .remoteUrl(
                                URL(string: "http://storage.example.com/build1234/FunctionalTests-Runner.zip#FunctionalTests-Runner.app")!,
                                nil
                            )
                        ),
                        additionalApplicationBundles: [
                            AdditionalAppBundleLocation(
                                .remoteUrl(
                                    URL(string: "http://storage.example.com/build1234/FunctionalTests.zip#FunctionalTests.xctest")!,
                                    [
                                        "X-Comment": "URL to ZIP file containing addtional .app bundle. Usually this is useful for XC UI tests, which can run additinal apps during test execution",
                                    ]
                                )
                            )
                        ]
                    ),
                    developerDir: DeveloperDir.useXcode(
                        CFBundleShortVersionString: "13.1 - e.g. for Xcode 13.1. Provide here an Xcode version which should be used"
                    ),
                    environment: [
                        "SomeEnvName": "These envs will be available from inside tests, usually via ProcessInfo.environment API",
                    ],
                    userInsertedLibraries: [],
                    numberOfRetries: 0,
                    testRetryMode: .retryThroughQueue,
                    logCapturingMode: .onlyCrashLogs,
                    runnerWasteCleanupPolicy: .clean,
                    pluginLocations: [
                        AppleTestPluginLocation(
                            .remoteUrl(
                                URL(string: "http://storage.example.com/emceeplugins/MyPlugin.zip#MyPlugin.emceeplugin")!,
                                [
                                    "X-Comment": "URL to ZIP file containing Emcee plugin bundle with .emceeplugin extension",
                                    "X-Docs": "Please refer to https://github.com/avito-tech/Emcee/wiki/Plugins for more information about plugins",
                                ]
                            )
                        ),
                    ],
                    scheduleStrategy: TestArgFileDefaultValues.scheduleStrategy,
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
                    testTimeoutConfiguration: TestArgFileDefaultValues.testTimeoutConfiguration,
                    testAttachmentLifetime: TestArgFileDefaultValues.testAttachmentLifetime,
                    testsToRun: [
                        .testName(TestName(className: "ClassName", methodName: "test")),
                        .testName(TestName(className: "ClassName", methodName: "testSpecificTestMethodName__youCanRepeatTestNamesMultipleTimes__toMakeTestRunSeveralTimes")),
                        .testName(TestName(className: "ClassName", methodName: "testSpecificTestMethodName__youCanRepeatTestNamesMultipleTimes__toMakeTestRunSeveralTimes")),
                        .allDiscoveredTests,
                    ],
                    workerCapabilityRequirements: [
                        WorkerCapabilityRequirement(
                            capabilityName: XcodeCapabilitiesProvider.workerCapabilityName(
                                shortVersion: "13.1 —— this requirement enforces that tests will only run on workers satisfying this Xcode version requirement."
                            ),
                            constraint: .present
                        )
                    ],
                    collectResultBundles: false
                )
            ],
            prioritizedJob: PrioritizedJob(
                analyticsConfiguration: AnalyticsConfiguration(
                    graphiteConfiguration: MetricConfiguration(
                        socketAddress: SocketAddress(
                            host: "graphite.example.com — this is a host name which runs Graphite instance, and its port. Please also refer to https://github.com/avito-tech/Emcee/wiki/Graphite",
                            port: 42
                        ),
                        metricPrefix: "some.prefix.for.emcee"
                    ),
                    statsdConfiguration: MetricConfiguration(
                        socketAddress: SocketAddress(
                            host: "statsd.example.com — this is a host name which runs Statsd instance, and its port. Please also refer to https://github.com/avito-tech/Emcee/wiki/Graphite",
                            port: 1234
                        ),
                        metricPrefix: "some.prefix.for.emcee"
                    ),
                    kibanaConfiguration: KibanaConfiguration(
                        endpoints: [
                            URL(string: "http://kibana.example.com:12345/")!,
                        ],
                        indexPattern: "emcee-index-16112021-"
                    ),
                    persistentMetricsJobId: "UnitTests - set this to allow reporting top-level metrics for jobs with this persistent ID. Useful for statsd metrics which describe top level behaviour of these jobs.",
                    metadata: [
                        "ciBranchName": "SomeBranchNameWhereTestsAreRunning",
                        "whatisthis": "These values are used for logging purposes. E.g. in Kibana, you can then filter logs by these values.",
                    ]
                ),
                jobGroupId: JobGroupId(
                    "This is an unique value, e.g. uuid, but it should be common of multiple jobs that are part of the same job group. Please refer to https://github.com/avito-tech/Emcee/wiki/Test-Arg-File#schema."
                ),
                jobGroupPriority: Priority(750),
                jobId: JobId("This is unique job id. Emcee queue will store test results under this key. Please note, that running additional test run with the same job id will APPEND the test results into previous run. It is better to change this value for each run. UUID can be safely used for this purposes, probably with some human readable additions for ease of understanding, e.g. PR1234_UnitTest_F80A8B88-A209-4694-8847-DC797642655C"),
                jobPriority: .medium
            ),
            testDestinationConfigurations: [
                TestDestinationConfiguration(
                    testDestination: testDestination,
                    reportOutput: ReportOutput(
                        junit: "Absolute path to where junit specific for _this test destination_ should be created. --junit will contain the complete junit report.",
                        tracingReport: "Absolute path to where Chrome trace specific for _this test destination_ should be created. --trace will contain the complete trace for the whole test run.",
                        resultBundle: "Absolute path merged result bundle from xcodebuild invokations. --resultBundle"
                    )
                ),
            ]
        )
        
        let data = try JSONEncoder.pretty().encode(testArgFile)
        try data.write(to: outputPath.fileUrl)
        
        logger.info("Generated test arg file stored at \(outputPath)")
    }
}
