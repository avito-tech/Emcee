// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "EmceeTestRunner",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        // MARK: - Products
        .executable(
            // MARK: Emcee
            name: "Emcee",
            targets: [
                "EmceeBinary",
            ]
        ),
        .library(
            // MARK: EmceePlugin
            name: "EmceePlugin",
            targets: [
                "Models",
                "Logging",
                "Plugin",
            ]
        ),
        .library(
            // MARK: EmceeInterfaces
            name: "EmceeInterfaces",
            targets: [
                "Models",
                "RuntimeDump",
            ]
        ),
        .executable(
            // MARK: testing_plugin
            name: "testing_plugin",
            targets: ["TestingPlugin"]
        )
    ],
    dependencies: [
        // MARK: - Dependencies
        .package(url: "https://github.com/0x7fs/CountedSet", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", .exact("1.0.16")),
        .package(url: "https://github.com/Weebly/OrderedSet", .exact("5.0.0")),
        .package(url: "https://github.com/avito-tech/GraphiteClient.git", .branch("master")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .exact("3.0.6")),
        .package(url: "https://github.com/httpswift/swifter.git", .exact("1.4.6")),
        .package(url: "https://github.com/jakeheis/Shout.git", .branch("master"))
    ],
    targets: [
        // MARK: - Targets
        .target(
            // MARK: Ansi
            name: "Ansi",
            dependencies: [
            ]
        ),
        .target(
            // MARK: AppleTools
            name: "AppleTools",
            dependencies: [
                "DeveloperDirLocator",
                "Logging",
                "Models",
                "ProcessController",
                "ResourceLocationResolver",
                "Runner",
                "SimulatorPool",
                "TemporaryStuff",
                "XcTestRun",
            ]
        ),
        .testTarget(
            // MARK: AppleToolsTests
            name: "AppleToolsTests",
            dependencies: [
                "AppleTools",
                "DeveloperDirLocatorTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: ArgLib
            name: "ArgLib",
            dependencies: [
                "OrderedSet"
            ]
        ),
        .testTarget(
            // MARK: ArgLibTests
            name: "ArgLibTests",
            dependencies: [
                "ArgLib",
                "OrderedSet"
            ]
        ),
        .target(
            // MARK: AutomaticTermination
            name: "AutomaticTermination",
            dependencies: [
                "DateProvider",
                "Logging",
                "Timer"
            ]
        ),
        .target(
            // MARK: AutomaticTerminationTestHelpers
            name: "AutomaticTerminationTestHelpers",
            dependencies: [
                "AutomaticTermination"
            ],
            path: "Tests/AutomaticTerminationTestHelpers"
        ),
        .testTarget(
            // MARK: AutomaticTerminationTests
            name: "AutomaticTerminationTests",
            dependencies: [
                "AutomaticTermination",
                "AutomaticTerminationTestHelpers",
                "DateProvider"
            ]
        ),
        .target(
            // MARK: BalancingBucketQueue
            name: "BalancingBucketQueue",
            dependencies: [
                "BucketQueue",
                "DateProvider",
                "Logging",
                "Models",
                "ResultsCollector"
            ]
        ),
        .testTarget(
            // MARK: BalancingBucketQueueTests
            name: "BalancingBucketQueueTests",
            dependencies: [
                "BalancingBucketQueue",
                "BucketQueueTestHelpers",
                "ResultsCollector",
                "UniqueIdentifierGenerator",
                "WorkerAlivenessProvider",
                "WorkerAlivenessProviderTestHelpers",
            ]
        ),
        .target(
            // MARK: BucketQueue
            name: "BucketQueue",
            dependencies: [
                "DateProvider",
                "Logging",
                "Models",
                "UniqueIdentifierGenerator",
                "WorkerAlivenessProvider"
            ]
        ),
        .target(
            // MARK: BucketQueueTestHelpers
            name: "BucketQueueTestHelpers",
            dependencies: [
                "BucketQueue",
                "DateProviderTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider"
            ],
            path: "Tests/BucketQueueTestHelpers"
        ),
        .testTarget(
            // MARK: BucketQueueTests
            name: "BucketQueueTests",
            dependencies: [
                "BucketQueue",
                "BucketQueueTestHelpers",
                "DateProviderTestHelpers",
                "ModelsTestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProviderTestHelpers"
            ]
        ),
        .target(
            // MARK: ChromeTracing
            name: "ChromeTracing",
            dependencies: [
                "Extensions",
                "Models"
            ]
        ),
        .target(
            // MARK: CurrentlyBeingProcessedBucketsTracker
            name: "CurrentlyBeingProcessedBucketsTracker",
            dependencies: [
                "CountedSet",
                "Models"
            ]
        ),
        .testTarget(
            // MARK: CurrentlyBeingProcessedBucketsTrackerTests
            name: "CurrentlyBeingProcessedBucketsTrackerTests",
            dependencies: [
                "CurrentlyBeingProcessedBucketsTracker"
            ]
        ),
        .target(
            // MARK: DateProvider
            name: "DateProvider",
            dependencies: []
        ),
        .target(
            // MARK: DateProviderTestHelpers
            name: "DateProviderTestHelpers",
            dependencies: [
                "DateProvider"
            ],
            path: "Tests/DateProviderTestHelpers"
        ),
        .target(
            // MARK: Deployer
            name: "Deployer",
            dependencies: [
                "Extensions",
                "Logging",
                "Models",
                "PathLib",
                "ProcessController",
                "TemporaryStuff"
            ]
        ),
        .testTarget(
            // MARK: DeployerTests
            name: "DeployerTests",
            dependencies: [
                "Deployer"
            ]
        ),
        .target(
            // MARK: DeveloperDirLocator
            name: "DeveloperDirLocator",
            dependencies: [
                "ProcessController"
            ]
        ),
        .target(
            // MARK: DeveloperDirLocatorTestHelpers
            name: "DeveloperDirLocatorTestHelpers",
            dependencies: [
                "DeveloperDirLocator",
                "Models",
                "PathLib",
            ],
            path: "Tests/DeveloperDirLocatorTestHelpers"
        ),
        .testTarget(
            // MARK: DeveloperDirLocatorTests
            name: "DeveloperDirLocatorTests",
            dependencies: [
                "DeveloperDirLocator",
                "Models",
                "PathLib",
                "ProcessController",
                "TemporaryStuff"
            ]
        ),
        .target(
            // MARK: DistDeployer
            name: "DistDeployer",
            dependencies: [
                "Deployer",
                "LaunchdUtils",
                "Logging",
                "Models",
                "PathLib",
                "SSHDeployer",
                "TemporaryStuff",
                "Version"
            ]
        ),
        .testTarget(
            // MARK: DistDeployerTests
            name: "DistDeployerTests",
            dependencies: [
                "Deployer",
                "DistDeployer",
                "Extensions",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "ResourceLocationResolver",
                "TemporaryStuff"
            ]
        ),
        .target(
            // MARK: DistWorker
            name: "DistWorker",
            dependencies: [
                "CurrentlyBeingProcessedBucketsTracker",
                "DeveloperDirLocator",
                "EventBus",
                "Extensions",
                "Logging",
                "Models",
                "PluginManager",
                "QueueClient",
                "RESTMethods",
                "ResourceLocationResolver",
                "Runner",
                "Scheduler",
                "SimulatorPool",
                "SynchronousWaiter",
                "TemporaryStuff",
                "Timer",
            ]
        ),
        .testTarget(
            // MARK: DistWorkerTests
            name: "DistWorkerTests",
            dependencies: [
                "DistWorker",
                "ModelsTestHelpers",
                "Scheduler"
            ]
        ),
        .target(
            // MARK: EmceeBinary
            name: "EmceeBinary",
            dependencies: [
                "EmceeLib"
            ]
        ),
        .target(
            // MARK: EmceeLib
            name: "EmceeLib",
            dependencies: [
                "AppleTools",
                "ArgLib",
                "ChromeTracing",
                "Deployer",
                "DeveloperDirLocator",
                "DistWorker",
                "EventBus",
                "FileCache",
                "JunitReporting",
                "LaunchdUtils",
                "LocalQueueServerRunner",
                "LoggingSetup",
                "Metrics",
                "Models",
                "PathLib",
                "PluginManager",
                "PortDeterminer",
                "ProcessController",
                "RemoteQueue",
                "RequestSender",
                "ResourceLocationResolver",
                "Runner",
                "SSHDeployer",
                "ScheduleStrategy",
                "Scheduler",
                "SignalHandling",
                "TemporaryStuff",
                "URLResource",
                "UniqueIdentifierGenerator",
                "Version",
                "fbxctest",
            ]
        ),
        .testTarget(
            // MARK: EmceeLibTests
            name: "EmceeLibTests",
            dependencies: [
                "EmceeLib",
                "Models",
                "ModelsTestHelpers"
            ]
        ),
        .target(
            // MARK: EventBus
            name: "EventBus",
            dependencies: [
                "Logging",
                "Models"
            ]
        ),
        .testTarget(
            // MARK: EventBusTests
            name: "EventBusTests",
            dependencies: [
                "EventBus",
                "ModelsTestHelpers",
                "SynchronousWaiter"
            ]
        ),
        .target(
            // MARK: Extensions
            name: "Extensions",
            dependencies: [
            ]
        ),
        .testTarget(
            // MARK: ExtensionsTests
            name: "ExtensionsTests",
            dependencies: [
                "Extensions",
                "TemporaryStuff"
            ]
        ),
        .target(
            // MARK: fbxctest
            name: "fbxctest",
            dependencies: [
                "Ansi",
                "DeveloperDirLocator",
                "JSONStream",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "Models",
                "ProcessController",
                "Runner",
                "SimulatorPool",
                "SynchronousWaiter",
                "TemporaryStuff",
                "Timer",
            ]
        ),
        .testTarget(
            // MARK: fbxctestTests
            name: "fbxctestTests",
            dependencies: [
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "JSONStream",
                "Models",
                "ModelsTestHelpers",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "TemporaryStuff",
                "fbxctest",
            ]
        ),
        .target(
            // MARK: FileCache
            name: "FileCache",
            dependencies: [
                "Extensions",
                "Models",
                "UniqueIdentifierGenerator",
            ]
        ),
        .testTarget(
            // MARK: FileCacheTests
            name: "FileCacheTests",
            dependencies: [
                "FileCache",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers"
            ]
        ),
        .target(
            // MARK: FileHasher
            name: "FileHasher",
            dependencies: [
                "AtomicModels",
                "Extensions",
                "Models"
            ]
        ),
        .testTarget(
            // MARK: FileHasherTests
            name: "FileHasherTests",
            dependencies: [
                "FileHasher",
                "TemporaryStuff"
            ]
        ),
        .target(
            // MARK: LocalHostDeterminer
            name: "LocalHostDeterminer",
            dependencies: [
                "Logging"
            ]
        ),
        .target(
            // MARK: JSONStream
            name: "JSONStream",
            dependencies: []
        ),
        .testTarget(
            // MARK: JSONStreamTests
            name: "JSONStreamTests",
            dependencies: [
                "JSONStream"
            ]
        ),
        .target(
            // MARK: JunitReporting
            name: "JunitReporting",
            dependencies: [
            ]
        ),
        .testTarget(
            // MARK: JunitReportingTests
            name: "JunitReportingTests",
            dependencies: [
                "Extensions",
                "JunitReporting"
            ]
        ),
        .target(
            // MARK: LaunchdUtils
            name: "LaunchdUtils",
            dependencies: [
            ]
        ),
        .testTarget(
            // MARK: LaunchdUtilsTests
            name: "LaunchdUtilsTests",
            dependencies: [
                "LaunchdUtils"
            ]
        ),
        .target(
            // MARK: ListeningSemaphore
            name: "ListeningSemaphore",
            dependencies: [
            ]
        ),
        .testTarget(
            // MARK: ListeningSemaphoreTests
            name: "ListeningSemaphoreTests",
            dependencies: [
                "ListeningSemaphore"
            ]
        ),
        .target(
            // MARK: LocalQueueServerRunner
            name: "LocalQueueServerRunner",
            dependencies: [
                "AutomaticTermination",
                "DateProvider",
                "DistDeployer",
                "LocalHostDeterminer",
                "Logging",
                "Models",
                "PortDeterminer",
                "QueueServer",
                "RemotePortDeterminer",
                "RequestSender",
                "ScheduleStrategy",
                "SynchronousWaiter",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
                "Version",
            ]
        ),
        .testTarget(
            // MARK: LocalQueueServerRunnerTests
            name: "LocalQueueServerRunnerTests",
            dependencies: [
                "AutomaticTermination",
                "AutomaticTerminationTestHelpers",
                "LocalQueueServerRunner",
                "QueueServerTestHelpers",
                "RemotePortDeterminer",
                "RemotePortDeterminerTestHelpers",
                "TemporaryStuff",
                "Version",
                "VersionTestHelpers",
            ]
        ),
        .target(
            // MARK: Logging
            name: "Logging",
            dependencies: [
                "Ansi",
                "AtomicModels",
                "Extensions"
            ]
        ),
        .target(
            // MARK: LoggingSetup
            name: "LoggingSetup",
            dependencies: [
                "Ansi",
                "GraphiteClient",
                "IO",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "PathLib",
                "Sentry",
                "TemporaryStuff",
                "Version"
            ]
        ),
        .testTarget(
            // MARK: LoggingTests
            name: "LoggingTests",
            dependencies: [
                "Logging",
                "TemporaryStuff"
            ]
        ),
        .target(
            // MARK: Metrics
            name: "Metrics",
            dependencies: []
        ),
        .testTarget(
            // MARK: MetricsTests
            name: "MetricsTests",
            dependencies: [
                "Metrics"
            ]
        ),
        .target(
            // MARK: Models
            name: "Models",
            dependencies: [
                "Extensions"
            ]
        ),
        .target(
            // MARK: ModelsTestHelpers
            name: "ModelsTestHelpers",
            dependencies: [
                "Models",
                "ScheduleStrategy"
            ],
            path: "Tests/ModelsTestHelpers"
        ),
        .testTarget(
            // MARK: ModelsTests
            name: "ModelsTests",
            dependencies: [
                "Models",
                "ModelsTestHelpers",
                "TestHelpers",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: PathLib
            name: "PathLib",
            dependencies: [
            ]
        ),
        .testTarget(
            // MARK: PathLibTests
            name: "PathLibTests",
            dependencies: [
                "PathLib"
            ]
        ),
        .target(
            // MARK: Plugin
            name: "Plugin",
            dependencies: [
                "EventBus",
                "JSONStream",
                "Logging",
                "LoggingSetup",
                "Models",
                "ResourceLocationResolver",
                "SimulatorVideoRecorder",
                "Starscream",
                "SynchronousWaiter",
                "TestsWorkingDirectorySupport",
            ]
        ),
        .target(
            // MARK: PluginManager
            name: "PluginManager",
            dependencies: [
                "EventBus",
                "LocalHostDeterminer",
                "Logging",
                "ResourceLocationResolver",
                "Models",
                "PathLib",
                "ProcessController",
                "Scheduler",
                "Swifter",
                "SynchronousWaiter"
            ]
        ),
        .testTarget(
            // MARK: PluginManagerTests
            name: "PluginManagerTests",
            dependencies: [
                "EventBus",
                "Models",
                "ModelsTestHelpers",
                "PluginManager",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: PortDeterminer
            name: "PortDeterminer",
            dependencies: [
                "Logging",
                "Swifter"
            ]
        ),
        .testTarget(
            // MARK: PortDeterminerTests
            name: "PortDeterminerTests",
            dependencies: [
                "PortDeterminer",
                "Swifter"
            ]
        ),
        .target(
            // MARK: ProcessController
            name: "ProcessController",
            dependencies: [
                "Extensions",
                "Logging",
                "PathLib",
                "Timer",
            ]
        ),
        .target(
            //MARK: ProcessControllerTestHelpers
            name: "ProcessControllerTestHelpers",
            dependencies: [
                "ProcessController",
            ],
            path: "Tests/ProcessControllerTestHelpers/"
        ),
        .testTarget(
            // MARK: ProcessControllerTests
            name: "ProcessControllerTests",
            dependencies: [
                "Extensions",
                "PathLib",
                "ProcessController",
                "TemporaryStuff"
            ]
        ),
        .target(
            // MARK: QueueClient
            name: "QueueClient",
            dependencies: [
                "Logging",
                "Models",
                "RESTMethods",
                "RequestSender",
                "SynchronousWaiter",
                "Version"
            ]
        ),
        .testTarget(
            // MARK: QueueClientTests
            name: "QueueClientTests",
            dependencies: [
                "Models",
                "ModelsTestHelpers",
                "PortDeterminer",
                "QueueClient",
                "QueueServer",
                "RESTMethods",
                "Swifter",
                "SynchronousWaiter"
            ]
        ),
        .target(
            // MARK: QueueServer
            name: "QueueServer",
            dependencies: [
                "AutomaticTermination",
                "BalancingBucketQueue",
                "BucketQueue",
                "DateProvider",
                "EventBus",
                "Extensions",
                "FileHasher",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "Models",
                "PortDeterminer",
                "RESTMethods",
                "RESTServer",
                "RequestSenderTestHelpers",
                "ResultsCollector",
                "ScheduleStrategy",
                "Swifter",
                "SynchronousWaiter",
                "Timer",
                "UniqueIdentifierGenerator",
                "Version",
                "WorkerAlivenessProvider"
            ]
        ),
        .target(
            // MARK: QueueServerTestHelpers
            name: "QueueServerTestHelpers",
            dependencies: [
                "QueueServer"
            ],
            path: "Tests/QueueServerTestHelpers"
        ),
        .testTarget(
            // MARK: QueueServerTests
            name: "QueueServerTests",
            dependencies: [
                "AutomaticTermination",
                "AutomaticTerminationTestHelpers",
                "BalancingBucketQueue",
                "BucketQueue",
                "BucketQueueTestHelpers",
                "DateProviderTestHelpers",
                "Deployer",
                "EventBus",
                "FileHasher",
                "Models",
                "ModelsTestHelpers",
                "QueueClient",
                "QueueServer",
                "QueueServerTestHelpers",
                "RESTMethods",
                "RESTServer",
                "RESTServerTestHelpers",
                "ResourceLocationResolver",
                "ResultsCollector",
                "RequestSenderTestHelpers",
                "ScheduleStrategy",
                "TemporaryStuff",
                "TestHelpers",
                "UniqueIdentifierGeneratorTestHelpers",
                "VersionTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerAlivenessProviderTestHelpers"
            ]
        ),
        .target(
            // MARK: RemotePortDeterminer
            name: "RemotePortDeterminer",
            dependencies: [
                "AtomicModels",
                "QueueClient",
                "RequestSender",
                "Version"
            ]
        ),
        .target(
            // MARK: RemotePortDeterminerTestHelpers
            name: "RemotePortDeterminerTestHelpers",
            dependencies: [
                "RemotePortDeterminer"
            ],
            path: "Tests/RemotePortDeterminerTestHelpers"
        ),
        .testTarget(
            // MARK: RemotePortDeterminerTests
            name: "RemotePortDeterminerTests",
            dependencies: [
                "PortDeterminer",
                "RemotePortDeterminer",
                "RequestSender",
                "RequestSenderTestHelpers"
            ]
        ),
        .target(
            // MARK: RemoteQueue
            name: "RemoteQueue",
            dependencies: [
                "DistDeployer",
                "Models",
                "RemotePortDeterminer",
                "SSHDeployer",
                "Version"
            ]
        ),
        .testTarget(
            // MARK: RemoteQueueTests
            name: "RemoteQueueTests",
            dependencies: [
                "RemotePortDeterminerTestHelpers",
                "RemoteQueue",
                "VersionTestHelpers"
            ]
        ),
        .target(
            // MARK: RequestSender
            name: "RequestSender",
            dependencies: [
                "Extensions",
                "Logging",
                "Models"
            ]
        ),
        .target(
            // MARK: RequestSenderTestHelpers
            name: "RequestSenderTestHelpers",
            dependencies: [
                "RequestSender"
            ],
            path: "Tests/RequestSenderTestHelpers"
        ),
        .testTarget(
            // MARK: RequestSenderTests
            name: "RequestSenderTests",
            dependencies: [
                "Models",
                "ModelsTestHelpers",
                "RequestSender",
                "RequestSenderTestHelpers",
                "Swifter",
            ]
        ),
        .target(
            // MARK: ResultsCollector
            name: "ResultsCollector",
            dependencies: [
                "Models"
            ]
        ),
        .testTarget(
            // MARK: ResultsCollectorTests
            name: "ResultsCollectorTests",
            dependencies: [
                "ModelsTestHelpers",
                "ResultsCollector"
            ]
        ),
        .target(
            // MARK: ResourceLocationResolver
            name: "ResourceLocationResolver",
            dependencies: [
                "AtomicModels",
                "Extensions",
                "FileCache",
                "Models",
                "ProcessController",
                "URLResource",
            ]
        ),
        .target(
            // MARK: ResourceLocationResolverTestHelpers
            name: "ResourceLocationResolverTestHelpers",
            dependencies: [
                "Models",
                "ResourceLocationResolver",
            ],
            path: "Tests/ResourceLocationResolverTestHelpers"
        ),
        .testTarget(
            // MARK: ResourceLocationResolverTests
            name: "ResourceLocationResolverTests",
            dependencies: [
                "FileCache",
                "PathLib",
                "ResourceLocationResolver",
                "Swifter",
                "TemporaryStuff",
                "URLResource"
            ]
        ),
        .target(
            // MARK: RESTMethods
            name: "RESTMethods",
            dependencies: [
                "Models",
                "Version"
            ]
        ),
        .target(
            // MARK: RESTServer
            name: "RESTServer",
            dependencies: [
                "AutomaticTermination",
                "Extensions",
                "Logging",
                "Models",
                "RESTMethods",
                "Swifter",
            ]
        ),
        .target(
            name: "RESTServerTestHelpers",
            dependencies: [
                "RESTServer",
            ],
            path: "Tests/RESTServerTestHelpers"
        ),
        .testTarget(
            name: "RESTServerTests",
            dependencies: [
                "RESTMethods",
                "RESTServer",
                "Swifter",
            ]
        ),
        .target(
            // MARK: Runner
            name: "Runner",
            dependencies: [
                "EventBus",
                "DeveloperDirLocator",
                "LocalHostDeterminer",
                "Logging",
                "Models",
                "PathLib",
                "SimulatorPool",
                "TemporaryStuff",
                "TestsWorkingDirectorySupport"
            ]
        ),
        .target(
            // MARK: RunnerTestHelpers
            name: "RunnerTestHelpers",
            dependencies: [
                "Models",
                "Runner",
                "ProcessController",
                "TemporaryStuff",
            ],
            path: "Tests/RunnerTestHelpers"
        ),
        .testTarget(
            // MARK: RunnerTests
            name: "RunnerTests",
            dependencies: [
                "DeveloperDirLocatorTestHelpers",
                "Extensions",
                "Metrics",
                "Models",
                "ModelsTestHelpers",
                "ProcessController",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "RunnerTestHelpers",
                "ScheduleStrategy",
                "SimulatorPool",
                "TemporaryStuff"
            ]
        ),
        .target(
            // MARK: RuntimeDump
            name: "RuntimeDump",
            dependencies: [
                "DeveloperDirLocator",
                "EventBus",
                "Extensions",
                "Metrics",
                "Models",
                "PathLib",
                "Runner",
                "SynchronousWaiter",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
            ]
        ),
        .testTarget(
            // MARK: RuntimeDumpTests
            name: "RuntimeDumpTests",
            dependencies: [
                "DeveloperDirLocatorTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "RunnerTestHelpers",
                "RuntimeDump",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ]
        ),
        .target(
            // MARK: Sentry
            name: "Sentry",
            dependencies: []
        ),
        .testTarget(
            // MARK: SentryTests
            name: "SentryTests",
            dependencies: [
                "Sentry"
            ]
        ),
        .target(
            // MARK: Scheduler
            name: "Scheduler",
            dependencies: [
                "DeveloperDirLocator",
                "EventBus",
                "ListeningSemaphore",
                "Logging",
                "Models",
                "Runner",
                "RuntimeDump",
                "ScheduleStrategy",
                "SimulatorPool",
                "SynchronousWaiter",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
            ]
        ),
        .target(
            // MARK: ScheduleStrategy
            name: "ScheduleStrategy",
            dependencies: [
                "Extensions",
                "Logging",
                "Models",
                "UniqueIdentifierGenerator"
            ]
        ),
        .testTarget(
            // MARK: ScheduleStrategyTests
            name: "ScheduleStrategyTests",
            dependencies: [
                "Models",
                "ModelsTestHelpers",
                "ScheduleStrategy",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                ]
        ),
        .target(
            // MARK: SignalHandling
            name: "SignalHandling",
            dependencies: [
                "Models",
                "Signals"
            ]
        ),
        .testTarget(
            // MARK: SignalHandlingTests
            name: "SignalHandlingTests",
            dependencies: [
                "SignalHandling",
                "Signals"
            ]
        ),
        .target(
            // MARK: SimulatorPool
            name: "SimulatorPool",
            dependencies: [
                "DeveloperDirLocator",
                "Extensions",
                "Logging",
                "Models",
                "ProcessController",
                "ResourceLocationResolver",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: SimulatorPoolTestHelpers
            name: "SimulatorPoolTestHelpers",
            dependencies: [
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "SimulatorPool",
                "TemporaryStuff",
            ],
            path: "Tests/SimulatorPoolTestHelpers"
        ),
        .testTarget(
            // MARK: SimulatorPoolTests
            name: "SimulatorPoolTests",
            dependencies: [
                "DeveloperDirLocatorTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "ResourceLocationResolver",
                "SimulatorPool",
                "SimulatorPoolTestHelpers",
                "SynchronousWaiter",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: SimulatorVideoRecorder
            name: "SimulatorVideoRecorder",
            dependencies: [
                "Logging",
                "Models",
                "PathLib",
                "ProcessController",
            ]
        ),
        .target(
            // MARK: SSHDeployer
            name: "SSHDeployer",
            dependencies: [
                "Ansi",
                "Deployer",
                "Extensions",
                "Logging",
                "Models",
                "PathLib",
                "Shout"
            ]
        ),
        .testTarget(
            // MARK: SSHDeployerTests
            name: "SSHDeployerTests",
            dependencies: [
                "PathLib",
                "SSHDeployer"
            ]
        ),
        .target(
            // MARK: SynchronousWaiter
            name: "SynchronousWaiter",
            dependencies: [
                "Logging"
            ]
        ),
        .testTarget(
            // MARK: SynchronousWaiterTests
            name: "SynchronousWaiterTests",
            dependencies: [
                "SynchronousWaiter"
            ]
        ),
        .target(
            // MARK: TemporaryStuff
            name: "TemporaryStuff",
            dependencies: [
                "PathLib"
            ]
        ),
        .testTarget(
            // MARK: TemporaryStuffTests
            name: "TemporaryStuffTests",
            dependencies: [
                "PathLib",
                "TemporaryStuff"
            ]
        ),
        .target(
            // MARK: TestingPlugin
            name: "TestingPlugin",
            dependencies: [
                "Extensions",
                "Models",
                "Logging",
                "LoggingSetup",
                "Plugin"
            ]
        ),
        .target(
            // MARK: TestHelpers
            name: "TestHelpers",
            dependencies: [
            ],
            path: "Tests/TestHelpers"
        ),
        .target(
            // MARK: TestsWorkingDirectorySupport
            name: "TestsWorkingDirectorySupport",
            dependencies: [
                "Models",
                "PathLib",
            ]
        ),
        .target(
            // MARK: Timer
            name: "Timer",
            dependencies: [
            ]
        ),
        .target(
            // MARK: UniqueIdentifierGenerator
            name: "UniqueIdentifierGenerator",
            dependencies: [
            ]
        ),
        .target(
            // MARK: UniqueIdentifierGeneratorTestHelpers
            name: "UniqueIdentifierGeneratorTestHelpers",
            dependencies: [
                "UniqueIdentifierGenerator"
            ],
            path: "Tests/UniqueIdentifierGeneratorTestHelpers"
        ),
        .target(
            // MARK: URLResource
            name: "URLResource",
            dependencies: [
                "FileCache",
                "Logging",
                "Models",
                "SynchronousWaiter"
            ]
        ),
        .testTarget(
            // MARK: URLResourceTests
            name: "URLResourceTests",
            dependencies: [
                "FileCache",
                "Swifter",
                "TemporaryStuff",
                "URLResource"
            ]
        ),
        .target(
            // MARK: Version
            name: "Version",
            dependencies: [
                "FileHasher"
            ]
        ),
        .target(
            // MARK: VersionTestHelpers
            name: "VersionTestHelpers",
            dependencies: [
                "Version"
            ],
            path: "Tests/VersionTestHelpers"
        ),
        .testTarget(
            // MARK: VersionTests
            name: "VersionTests",
            dependencies: [
                "Extensions",
                "FileHasher",
                "TemporaryStuff",
                "Version"
            ]
        ),
        .target(
            // MARK: WorkerAlivenessProvider
            name: "WorkerAlivenessProvider",
            dependencies: [
                "DateProvider",
                "Logging",
                "Models"
            ]
        ),
        .target(
            // MARK: WorkerAlivenessProviderTestHelpers
            name: "WorkerAlivenessProviderTestHelpers",
            dependencies: [
                "DateProvider",
                "DateProviderTestHelpers",
                "WorkerAlivenessProvider"
            ],
            path: "Tests/WorkerAlivenessProviderTestHelpers"
        ),
        .testTarget(
            // MARK: WorkerAlivenessProviderTests
            name: "WorkerAlivenessProviderTests",
            dependencies: [
                "WorkerAlivenessProvider",
                "WorkerAlivenessProviderTestHelpers"
            ]
        ),
        .target(
            // MARK: XcTestRun
            name: "XcTestRun",
            dependencies: [
            ]
        ),
        .testTarget(
            // MARK: XcTestRunTests
            name: "XcTestRunTests",
            dependencies: [
                "XcTestRun"
            ]
        )
    ]
)
