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
                "BuildArtifacts",
                "Models",
                "PluginSupport",
                "QueueModels",
                "ResourceLocation",
                "RunnerModels",
                "SimulatorPoolModels",
                "TestArgFile",
                "TestDiscovery",
                "TypedResourceLocation",
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
        .package(url: "https://github.com/avito-tech/GraphiteClient.git", .exact("0.1.1")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .exact("3.0.6")),
        .package(url: "https://github.com/httpswift/swifter.git", .exact("1.4.6")),
        .package(url: "https://github.com/jakeheis/Shout.git", .exact("0.5.1"))
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
                "BuildArtifacts",
                "DateProvider",
                "DeveloperDirLocator",
                "Logging",
                "Models",
                "ProcessController",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                "TemporaryStuff",
                "XcTestRun",
            ]
        ),
        .testTarget(
            // MARK: AppleToolsTests
            name: "AppleToolsTests",
            dependencies: [
                "AppleTools",
                "BuildArtifactsTestHelpers",
                "DateProvider",
                "DateProviderTestHelpers",
                "DeveloperDirLocatorTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "QueueModelsTestHelpers",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
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
                "CountedSet",
                "DateProvider",
                "Logging",
                "Models",
                "QueueModels",
                "ResultsCollector",
            ]
        ),
        .testTarget(
            // MARK: BalancingBucketQueueTests
            name: "BalancingBucketQueueTests",
            dependencies: [
                "BalancingBucketQueue",
                "BucketQueue",
                "BucketQueueTestHelpers",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "DateProviderTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "ResultsCollector",
                "TestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerAlivenessProviderTestHelpers",
            ]
        ),
        .target(
            // MARK: BucketQueue
            name: "BucketQueue",
            dependencies: [
                "BuildArtifacts",
                "DateProvider",
                "Logging",
                "Models",
                "QueueModels",
                "RunnerModels",
                "UniqueIdentifierGenerator",
                "WorkerAlivenessProvider",
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
                "QueueModels",
                "QueueModelsTestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
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
                "DistWorkerModels",
                "ModelsTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProviderTestHelpers",
            ]
        ),
        .target(
            // MARK: BuildArtifacts
            name: "BuildArtifacts",
            dependencies: [
                "Models",
                "TypedResourceLocation",
            ]
        ),
        .target(
            // MARK: BuildArtifactsTestHelpers
            name: "BuildArtifactsTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "Models",
                "ModelsTestHelpers",
            ],
            path: "Tests/BuildArtifactsTestHelpers"
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
        .target(
            // MARK: DeployerTestHelpers
            name: "DeployerTestHelpers",
            dependencies: [
                "Deployer",
                "Models",
            ],
            path: "Tests/DeployerTestHelpers"
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
                "Models",
                "PathLib",
                "ProcessController",
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
                "TypedResourceLocation"
            ]
        ),
        .testTarget(
            // MARK: DistDeployerTests
            name: "DistDeployerTests",
            dependencies: [
                "Deployer",
                "DeployerTestHelpers",
                "DistDeployer",
                "Extensions",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "ResourceLocationResolver",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: DistWorker
            name: "DistWorker",
            dependencies: [
                "AutomaticTermination",
                "CurrentlyBeingProcessedBucketsTracker",
                "DeveloperDirLocator",
                "DistWorkerModels",
                "Extensions",
                "LocalHostDeterminer",
                "Logging",
                "Models",
                "PluginManager",
                "QueueClient",
                "RESTMethods",
                "RESTServer",
                "RequestSender",
                "ResourceLocationResolver",
                "Runner",
                "Scheduler",
                "SimulatorPool",
                "SynchronousWaiter",
                "TemporaryStuff",
                "Timer",
            ]
        ),
        .target(
            // MARK: DistWorkerModels
            name: "DistWorkerModels",
            dependencies: [
                "LoggingSetup",
                "Models",
            ]
        ),
        .target(
            // MARK: DistWorkerModelsTestHelpers
            name: "DistWorkerModelsTestHelpers",
            dependencies: [
                "DistWorkerModels",
                "LoggingSetup",
            ],
            path: "Tests/DistWorkerModelsTestHelpers"
        ),
        .testTarget(
            // MARK: DistWorkerModelsTests
            name: "DistWorkerModelsTests",
            dependencies: [
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
            ]
        ),
        .testTarget(
            // MARK: DistWorkerTests
            name: "DistWorkerTests",
            dependencies: [
                "BuildArtifactsTestHelpers",
                "CurrentlyBeingProcessedBucketsTracker",
                "DistWorker",
                "ModelsTestHelpers",
                "RequestSender",
                "RunnerTestHelpers",
                "Scheduler",
                "SimulatorPoolTestHelpers",
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
                "BuildArtifacts",
                "ChromeTracing",
                "Deployer",
                "DeveloperDirLocator",
                "DistWorker",
                "DistWorkerModels",
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
                "QueueClient",
                "QueueModels",
                "QueueServer",
                "RemoteQueue",
                "RequestSender",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "SSHDeployer",
                "ScheduleStrategy",
                "Scheduler",
                "SimulatorPoolModels",
                "SignalHandling",
                "TemporaryStuff",
                "TestArgFile",
                "TypedResourceLocation",
                "URLResource",
                "UniqueIdentifierGenerator",
                "fbxctest",
            ]
        ),
        .testTarget(
            // MARK: EmceeLibTests
            name: "EmceeLibTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "EmceeLib",
                "Models",
                "ModelsTestHelpers",
                "ProcessControllerTestHelpers",
                "QueueModelsTestHelpers",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "TestArgFile",
                "TestDiscovery",
                "TestHelpers",
                "UniqueIdentifierGeneratorTestHelpers",
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
                "BuildArtifacts",
                "DeveloperDirLocator",
                "JSONStream",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "Models",
                "ProcessController",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "Timer",
                "TypedResourceLocation",
            ]
        ),
        .testTarget(
            // MARK: fbxctestTests
            name: "fbxctestTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "JSONStream",
                "Models",
                "ModelsTestHelpers",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "fbxctest",
            ]
        ),
        .target(
            // MARK: FileCache
            name: "FileCache",
            dependencies: [
                "Extensions",
                "FileLock",
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
            // MARK: FileLock
            name: "FileLock",
            dependencies: [
            ]
        ),
        .testTarget(
            // MARK: FileLockTests
            name: "FileLockTests",
            dependencies: [
                "FileLock",
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
                "Deployer",
                "DistDeployer",
                "DistWorkerModels",
                "FileLock",
                "LocalHostDeterminer",
                "Logging",
                "LoggingSetup",
                "Models",
                "PortDeterminer",
                "QueueServer",
                "RemotePortDeterminer",
                "RequestSender",
                "ScheduleStrategy",
                "SynchronousWaiter",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
            ]
        ),
        .testTarget(
            // MARK: LocalQueueServerRunnerTests
            name: "LocalQueueServerRunnerTests",
            dependencies: [
                "AutomaticTermination",
                "AutomaticTerminationTestHelpers",
                "LocalQueueServerRunner",
                "QueueModels",
                "QueueServer",
                "QueueServerTestHelpers",
                "RemotePortDeterminer",
                "RemotePortDeterminerTestHelpers",
                "TemporaryStuff",
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
                "Models",
                "PathLib",
                "Sentry",
                "TemporaryStuff",
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
                "Extensions",
                "ResourceLocation",
                "TypedResourceLocation",
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
                "PluginSupport",
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
                "Models",
                "PathLib",
                "PluginSupport",
                "ProcessController",
                "ResourceLocationResolver",
                "Swifter",
                "SynchronousWaiter",
            ]
        ),
        .target(
            // MARK: PluginManagerTestHelpers
            name: "PluginManagerTestHelpers",
            dependencies: [
                "EventBus",
                "Models",
                "PluginManager",
                "PluginSupport",
            ],
            path: "Tests/PluginManagerTestHelpers"
        ),
        .testTarget(
            // MARK: PluginManagerTests
            name: "PluginManagerTests",
            dependencies: [
                "EventBus",
                "Models",
                "ModelsTestHelpers",
                "PluginManager",
                "PluginSupport",
                "ResourceLocation",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: PluginSupport
            name: "PluginSupport",
            dependencies: [
                "Models",
                "TypedResourceLocation",
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
                "TemporaryStuff",
                "TestHelpers",
            ]
        ),
        .target(
            // MARK: QueueClient
            name: "QueueClient",
            dependencies: [
                "DistWorkerModels",
                "Logging",
                "Models",
                "RESTMethods",
                "RequestSender",
                "ScheduleStrategy",
                "SynchronousWaiter"
            ]
        ),
        .testTarget(
            // MARK: QueueClientTests
            name: "QueueClientTests",
            dependencies: [
                "BuildArtifactsTestHelpers",
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PortDeterminer",
                "QueueClient",
                "QueueModels",
                "QueueModelsTestHelpers",
                "QueueServer",
                "RESTMethods",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "Swifter",
                "SynchronousWaiter",
            ]
        ),
        .target(
            // MARK: QueueModels
            name: "QueueModels",
            dependencies: [
                "BuildArtifacts",
                "Extensions",
                "Models",
                "PluginSupport",
                "RunnerModels",
                "SimulatorPoolModels",
            ]
        ),
        .target(
            // MARK: QueueModelsTestHelpers
            name: "QueueModelsTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "QueueModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
            ],
            path: "Tests/QueueModelsTestHelpers"
        ),
        .target(
            // MARK: QueueServer
            name: "QueueServer",
            dependencies: [
                "AtomicModels",
                "AutomaticTermination",
                "BalancingBucketQueue",
                "BucketQueue",
                "DateProvider",
                "DistWorkerModels",
                "Extensions",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "Models",
                "PortDeterminer",
                "QueueModels",
                "RESTMethods",
                "RESTServer",
                "RequestSenderTestHelpers",
                "ResultsCollector",
                "ScheduleStrategy",
                "Swifter",
                "SynchronousWaiter",
                "Timer",
                "UniqueIdentifierGenerator",
                "WorkerAlivenessProvider",
            ]
        ),
        .testTarget(
            // MARK: QueueModelsTests
            name: "QueueModelsTests",
            dependencies: [
                "QueueModels",
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
                "AtomicModels",
                "AutomaticTermination",
                "AutomaticTerminationTestHelpers",
                "BalancingBucketQueue",
                "BucketQueue",
                "BucketQueueTestHelpers",
                "DateProviderTestHelpers",
                "Deployer",
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "QueueClient",
                "QueueModels",
                "QueueModelsTestHelpers",
                "QueueServer",
                "QueueServerTestHelpers",
                "RESTMethods",
                "RESTServer",
                "RESTServerTestHelpers",
                "RequestSender",
                "RequestSenderTestHelpers",
                "ResourceLocationResolver",
                "ResultsCollector",
                "ScheduleStrategy",
                "Swifter",
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestHelpers",
                "UniqueIdentifierGeneratorTestHelpers",
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
                "RequestSender"
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
                "SSHDeployer"
            ]
        ),
        .testTarget(
            // MARK: RemoteQueueTests
            name: "RemoteQueueTests",
            dependencies: [
                "RemotePortDeterminerTestHelpers",
                "RemoteQueue"
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
            // MARK: ResourceLocation
            name: "ResourceLocation",
            dependencies: [
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
                "ResourceLocation",
                "SynchronousWaiter",
                "TypedResourceLocation",
                "URLResource",
            ]
        ),
        .target(
            // MARK: ResourceLocationResolverTestHelpers
            name: "ResourceLocationResolverTestHelpers",
            dependencies: [
                "Models",
                "PathLib",
                "ResourceLocation",
                "ResourceLocationResolver",
                "TemporaryStuff",
            ],
            path: "Tests/ResourceLocationResolverTestHelpers"
        ),
        .testTarget(
            // MARK: ResourceLocationResolverTests
            name: "ResourceLocationResolverTests",
            dependencies: [
                "FileCache",
                "PathLib",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Swifter",
                "TemporaryStuff",
                "TestHelpers",
                "URLResource",
            ]
        ),
        .testTarget(
            // MARK: ResourceLocationTests
            name: "ResourceLocationTests",
            dependencies: [
                "ResourceLocation",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: RESTMethods
            name: "RESTMethods",
            dependencies: [
                "DistWorkerModels",
                "Models",
                "QueueModels",
                "RequestSender",
                "ScheduleStrategy"
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
                "BuildArtifacts",
                "DeveloperDirLocator",
                "EventBus",
                "LocalHostDeterminer",
                "Logging",
                "Models",
                "PathLib",
                "PluginManager",
                "PluginSupport",
                "RunnerModels",
                "SimulatorPoolModels",
                "TemporaryStuff",
                "TestsWorkingDirectorySupport",
            ]
        ),
        .target(
            // MARK: RunnerModels
            name: "RunnerModels",
            dependencies: [
                "BuildArtifacts",
                "Models",
                "PluginSupport",
                "SimulatorPoolModels",
            ]
        ),
        .target(
            // MARK: RunnerTestHelpers
            name: "RunnerTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "Models",
                "Runner",
                "RunnerModels",
                "ProcessController",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
            ],
            path: "Tests/RunnerTestHelpers"
        ),
        .testTarget(
            // MARK: RunnerTests
            name: "RunnerTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "DeveloperDirLocatorTestHelpers",
                "Extensions",
                "Metrics",
                "Models",
                "ModelsTestHelpers",
                "PluginManagerTestHelpers",
                "ProcessController",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "ScheduleStrategy",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
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
                "BuildArtifacts",
                "DeveloperDirLocator",
                "ListeningSemaphore",
                "LocalHostDeterminer",
                "Logging",
                "Models",
                "PluginSupport",
                "QueueModels",
                "Runner",
                "RunnerModels",
                "ScheduleStrategy",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestDiscovery",
                "UniqueIdentifierGenerator",
            ]
        ),
        .target(
            // MARK: ScheduleStrategy
            name: "ScheduleStrategy",
            dependencies: [
                "BuildArtifacts",
                "Extensions",
                "Logging",
                "Models",
                "QueueModels",
                "RunnerModels",
                "SimulatorPoolModels",
                "UniqueIdentifierGenerator",
            ]
        ),
        .testTarget(
            // MARK: ScheduleStrategyTests
            name: "ScheduleStrategyTests",
            dependencies: [
                "Models",
                "ModelsTestHelpers",
                "PluginSupport",
                "QueueModels",
                "QueueModelsTestHelpers",
                "ScheduleStrategy",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
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
                "AutomaticTermination",
                "DeveloperDirLocator",
                "Extensions",
                "Logging",
                "Metrics",
                "Models",
                "ProcessController",
                "ResourceLocationResolver",
                "RunnerModels",
                "SimulatorPoolModels",
                "TemporaryStuff",
            ]
        ),
        .target(
            // MARK: SimulatorPoolModels
            name: "SimulatorPoolModels",
            dependencies: [
                "Extensions",
                "Models",
                "PathLib",
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
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
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
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestHelpers",
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
                "Logging",
            ]
        ),
        .testTarget(
            // MARK: SynchronousWaiterTests
            name: "SynchronousWaiterTests",
            dependencies: [
                "Models",
                "SynchronousWaiter",
                "TestHelpers",
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
            // MARK: TestArgFile
            name: "TestArgFile",
            dependencies: [
                "BuildArtifacts",
                "Models",
                "QueueModels",
                "RunnerModels",
                "ScheduleStrategy",
                "SimulatorPoolModels",
            ]
        ),
        .testTarget(
            // MARK: TestArgFileTests
            name: "TestArgFileTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PluginSupport",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TestArgFile",
                "TestHelpers",
            ]
        ),
        .target(
            // MARK: TestDiscovery
            name: "TestDiscovery",
            dependencies: [
                "AppleTools",
                "BuildArtifacts",
                "DeveloperDirLocator",
                "Extensions",
                "Logging",
                "Metrics",
                "Models",
                "PathLib",
                "PluginManager",
                "PluginSupport",
                "ProcessController",
                "RequestSender",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
            ]
        ),
        .testTarget(
            // MARK: TestDiscoveryTests
            name: "TestDiscoveryTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "ResourceLocation",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "TestDiscovery",
                "TestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
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
            // MARK: TypedResourceLocation
            name: "TypedResourceLocation",
            dependencies: [
                "ResourceLocation",
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
                "AtomicModels",
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
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestHelpers",
                "URLResource",
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
