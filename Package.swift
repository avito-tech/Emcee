// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "EmceeTestRunner",
    platforms: [
        .macOS(.v10_13),
    ],
    products: [
        .executable(
            name: "Emcee",
            targets: [
                "EmceeBinary",
            ]
        ),
        .library(
            name: "EmceePlugin",
            targets: [
                "Models",
                "Logging",
                "Plugin",
            ]
        ),
        .library(
            name: "EmceeInterfaces",
            targets: [
                "BuildArtifacts",
                "FileSystem",
                "Models",
                "PathLib",
                "PluginSupport",
                "QueueModels",
                "ResourceLocation",
                "ResourceLocationResolver",
                "RunnerModels",
                "SimulatorPoolModels",
                "SimulatorVideoRecorder",
                "TestArgFile",
                "TestDiscovery",
                "TypedResourceLocation",
            ]
        ),
        .executable(
            name: "testing_plugin",
            targets: ["TestingPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/0x7fs/CountedSet", .branch("master")),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", .exact("1.0.16")),
        .package(url: "https://github.com/Weebly/OrderedSet", .exact("5.0.0")),
        .package(url: "https://github.com/avito-tech/GraphiteClient.git", .exact("0.1.1")),
        .package(url: "https://github.com/daltoniam/Starscream.git", .exact("3.0.6")),
        .package(url: "https://github.com/httpswift/swifter.git", .exact("1.4.6")),
        .package(url: "https://github.com/jakeheis/Shout.git", .exact("0.5.4"))
    ],
    targets: [
        .target(
            // MARK: AppleTools
            name: "AppleTools",
            dependencies: [
                "BuildArtifacts",
                "DateProvider",
                "DeveloperDirLocator",
                "Logging",
                "Models",
                "PathLib",
                "ProcessController",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                "TemporaryStuff",
            ],
            path: "Sources/AppleTools"
        ),
        .testTarget(
            // MARK: AppleToolsTests
            name: "AppleToolsTests",
            dependencies: [
                "AppleTools",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "DateProvider",
                "DateProviderTestHelpers",
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "FileCache",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "QueueModelsTestHelpers",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "TestHelpers",
                "URLResource",
            ],
            path: "Tests/AppleToolsTests"
        ),
        .target(
            // MARK: ArgLib
            name: "ArgLib",
            dependencies: [
                "OrderedSet",
            ],
            path: "Sources/ArgLib"
        ),
        .testTarget(
            // MARK: ArgLibTests
            name: "ArgLibTests",
            dependencies: [
                "ArgLib",
            ],
            path: "Tests/ArgLibTests"
        ),
        .target(
            // MARK: AutomaticTermination
            name: "AutomaticTermination",
            dependencies: [
                "DateProvider",
                "Logging",
                "Timer",
            ],
            path: "Sources/AutomaticTermination"
        ),
        .target(
            // MARK: AutomaticTerminationTestHelpers
            name: "AutomaticTerminationTestHelpers",
            dependencies: [
                "AutomaticTermination",
            ],
            path: "Tests/AutomaticTerminationTestHelpers"
        ),
        .testTarget(
            // MARK: AutomaticTerminationTests
            name: "AutomaticTerminationTests",
            dependencies: [
                "AutomaticTermination",
                "DateProvider",
            ],
            path: "Tests/AutomaticTerminationTests"
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
                "QueueCommunication",
                "QueueModels",
            ],
            path: "Sources/BalancingBucketQueue"
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
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "TestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerAlivenessProviderTestHelpers",
            ],
            path: "Tests/BalancingBucketQueueTests"
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
            ],
            path: "Sources/BucketQueue"
        ),
        .target(
            // MARK: BucketQueueTestHelpers
            name: "BucketQueueTestHelpers",
            dependencies: [
                "BucketQueue",
                "DateProvider",
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
                "Models",
                "ModelsTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerAlivenessProviderTestHelpers",
            ],
            path: "Tests/BucketQueueTests"
        ),
        .target(
            // MARK: BuildArtifacts
            name: "BuildArtifacts",
            dependencies: [
                "TypedResourceLocation",
            ],
            path: "Sources/BuildArtifacts"
        ),
        .target(
            // MARK: BuildArtifactsTestHelpers
            name: "BuildArtifactsTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "Models",
            ],
            path: "Tests/BuildArtifactsTestHelpers"
        ),
        .target(
            // MARK: ChromeTracing
            name: "ChromeTracing",
            dependencies: [
                "Extensions",
                "Models",
            ],
            path: "Sources/ChromeTracing"
        ),
        .target(
            // MARK: DateProvider
            name: "DateProvider",
            dependencies: [
            ],
            path: "Sources/DateProvider"
        ),
        .target(
            // MARK: DateProviderTestHelpers
            name: "DateProviderTestHelpers",
            dependencies: [
                "DateProvider",
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
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/Deployer"
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
                "Deployer",
                "Extensions",
                "Models",
                "PathLib",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "TemporaryStuff",
                "TestHelpers",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/DeployerTests"
        ),
        .target(
            // MARK: DeveloperDirLocator
            name: "DeveloperDirLocator",
            dependencies: [
                "Models",
                "PathLib",
                "ProcessController",
            ],
            path: "Sources/DeveloperDirLocator"
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
                "ProcessControllerTestHelpers",
                "TemporaryStuff",
                "TestHelpers",
            ],
            path: "Tests/DeveloperDirLocatorTests"
        ),
        .target(
            // MARK: DistDeployer
            name: "DistDeployer",
            dependencies: [
                "Deployer",
                "Extensions",
                "LaunchdUtils",
                "Logging",
                "Models",
                "PathLib",
                "ProcessController",
                "SSHDeployer",
                "TemporaryStuff",
                "TypedResourceLocation",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/DistDeployer"
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
            ],
            path: "Tests/DistDeployerTests"
        ),
        .target(
            // MARK: DistWorker
            name: "DistWorker",
            dependencies: [
                "AutomaticTermination",
                "CountedSet",
                "DeveloperDirLocator",
                "DistWorkerModels",
                "EventBus",
                "LocalHostDeterminer",
                "Logging",
                "LoggingSetup",
                "Models",
                "PathLib",
                "PluginManager",
                "QueueClient",
                "RESTInterfaces",
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
            ],
            path: "Sources/DistWorker"
        ),
        .target(
            // MARK: DistWorkerModels
            name: "DistWorkerModels",
            dependencies: [
                "LoggingSetup",
                "Models",
                "RESTInterfaces",
            ],
            path: "Sources/DistWorkerModels"
        ),
        .target(
            // MARK: DistWorkerModelsTestHelpers
            name: "DistWorkerModelsTestHelpers",
            dependencies: [
                "DistWorkerModels",
                "LoggingSetup",
                "Models",
            ],
            path: "Tests/DistWorkerModelsTestHelpers"
        ),
        .testTarget(
            // MARK: DistWorkerModelsTests
            name: "DistWorkerModelsTests",
            dependencies: [
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
            ],
            path: "Tests/DistWorkerModelsTests"
        ),
        .testTarget(
            // MARK: DistWorkerTests
            name: "DistWorkerTests",
            dependencies: [
                "BuildArtifactsTestHelpers",
                "DistWorker",
                "Models",
                "ModelsTestHelpers",
                "RequestSender",
                "RunnerTestHelpers",
                "Scheduler",
                "SimulatorPoolTestHelpers",
            ],
            path: "Tests/DistWorkerTests"
        ),
        .target(
            // MARK: EmceeBinary
            name: "EmceeBinary",
            dependencies: [
                "EmceeLib",
            ],
            path: "Sources/EmceeBinary"
        ),
        .target(
            // MARK: EmceeLib
            name: "EmceeLib",
            dependencies: [
                "AppleTools",
                "ArgLib",
                "AtomicModels",
                "AutomaticTermination",
                "BucketQueue",
                "BuildArtifacts",
                "ChromeTracing",
                "DateProvider",
                "Deployer",
                "DeveloperDirLocator",
                "DistDeployer",
                "DistWorker",
                "DistWorkerModels",
                "EventBus",
                "Extensions",
                "FileCache",
                "FileSystem",
                "JunitReporting",
                "LocalHostDeterminer",
                "LocalQueueServerRunner",
                "Logging",
                "LoggingSetup",
                "Metrics",
                "Models",
                "PathLib",
                "PluginManager",
                "PortDeterminer",
                "ProcessController",
                "QueueClient",
                "QueueCommunication",
                "QueueModels",
                "QueueServer",
                "RemotePortDeterminer",
                "RequestSender",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "ScheduleStrategy",
                "Scheduler",
                "SignalHandling",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestArgFile",
                "TestDiscovery",
                "TypedResourceLocation",
                "URLResource",
                "UniqueIdentifierGenerator",
                "fbxctest",
            ],
            path: "Sources/EmceeLib"
        ),
        .testTarget(
            // MARK: EmceeLibTests
            name: "EmceeLibTests",
            dependencies: [
                "AppleTools",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "EmceeLib",
                "FileSystem",
                "FileSystemTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "ProcessControllerTestHelpers",
                "QueueModelsTestHelpers",
                "ResourceLocationResolverTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "TestArgFile",
                "TestDiscovery",
                "TestHelpers",
                "UniqueIdentifierGeneratorTestHelpers",
                "fbxctest",
            ],
            path: "Tests/EmceeLibTests"
        ),
        .target(
            // MARK: EventBus
            name: "EventBus",
            dependencies: [
                "Logging",
                "Models",
            ],
            path: "Sources/EventBus"
        ),
        .testTarget(
            // MARK: EventBusTests
            name: "EventBusTests",
            dependencies: [
                "EventBus",
                "Models",
                "ModelsTestHelpers",
                "SynchronousWaiter",
            ],
            path: "Tests/EventBusTests"
        ),
        .target(
            // MARK: Extensions
            name: "Extensions",
            dependencies: [
            ],
            path: "Sources/Extensions"
        ),
        .testTarget(
            // MARK: ExtensionsTests
            name: "ExtensionsTests",
            dependencies: [
                "Extensions",
                "TemporaryStuff",
            ],
            path: "Tests/ExtensionsTests"
        ),
        .target(
            // MARK: FileCache
            name: "FileCache",
            dependencies: [
                "Extensions",
                "FileLock",
                "Models",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/FileCache"
        ),
        .testTarget(
            // MARK: FileCacheTests
            name: "FileCacheTests",
            dependencies: [
                "FileCache",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/FileCacheTests"
        ),
        .target(
            // MARK: FileLock
            name: "FileLock",
            dependencies: [
            ],
            path: "Sources/FileLock"
        ),
        .testTarget(
            // MARK: FileLockTests
            name: "FileLockTests",
            dependencies: [
                "FileLock",
            ],
            path: "Tests/FileLockTests"
        ),
        .target(
            // MARK: FileSystem
            name: "FileSystem",
            dependencies: [
                "PathLib",
            ],
            path: "Sources/FileSystem"
        ),
        .target(
            // MARK: FileSystemTestHelpers
            name: "FileSystemTestHelpers",
            dependencies: [
                "FileSystem",
                "PathLib",
            ],
            path: "Tests/FileSystemTestHelpers"
        ),
        .testTarget(
            // MARK: FileSystemTests
            name: "FileSystemTests",
            dependencies: [
                "FileSystem",
                "PathLib",
                "TemporaryStuff",
                "TestHelpers",
            ],
            path: "Tests/FileSystemTests"
        ),
        .target(
            // MARK: JSONStream
            name: "JSONStream",
            dependencies: [
            ],
            path: "Sources/JSONStream"
        ),
        .testTarget(
            // MARK: JSONStreamTests
            name: "JSONStreamTests",
            dependencies: [
                "JSONStream",
            ],
            path: "Tests/JSONStreamTests"
        ),
        .target(
            // MARK: JunitReporting
            name: "JunitReporting",
            dependencies: [
            ],
            path: "Sources/JunitReporting"
        ),
        .testTarget(
            // MARK: JunitReportingTests
            name: "JunitReportingTests",
            dependencies: [
                "Extensions",
                "JunitReporting",
            ],
            path: "Tests/JunitReportingTests"
        ),
        .target(
            // MARK: LaunchdUtils
            name: "LaunchdUtils",
            dependencies: [
            ],
            path: "Sources/LaunchdUtils"
        ),
        .testTarget(
            // MARK: LaunchdUtilsTests
            name: "LaunchdUtilsTests",
            dependencies: [
                "LaunchdUtils",
            ],
            path: "Tests/LaunchdUtilsTests"
        ),
        .target(
            // MARK: ListeningSemaphore
            name: "ListeningSemaphore",
            dependencies: [
            ],
            path: "Sources/ListeningSemaphore"
        ),
        .testTarget(
            // MARK: ListeningSemaphoreTests
            name: "ListeningSemaphoreTests",
            dependencies: [
                "ListeningSemaphore",
            ],
            path: "Tests/ListeningSemaphoreTests"
        ),
        .target(
            // MARK: LocalHostDeterminer
            name: "LocalHostDeterminer",
            dependencies: [
                "Logging",
            ],
            path: "Sources/LocalHostDeterminer"
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
                "EventBus",
                "FileLock",
                "LocalHostDeterminer",
                "Logging",
                "LoggingSetup",
                "Models",
                "PortDeterminer",
                "ProcessController",
                "QueueCommunication",
                "QueueServer",
                "RemotePortDeterminer",
                "RequestSender",
                "ScheduleStrategy",
                "SynchronousWaiter",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/LocalQueueServerRunner"
        ),
        .testTarget(
            // MARK: LocalQueueServerRunnerTests
            name: "LocalQueueServerRunnerTests",
            dependencies: [
                "AutomaticTermination",
                "AutomaticTerminationTestHelpers",
                "LocalQueueServerRunner",
                "Models",
                "ProcessControllerTestHelpers",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueServer",
                "QueueServerTestHelpers",
                "RemotePortDeterminer",
                "RemotePortDeterminerTestHelpers",
                "ScheduleStrategy",
                "TemporaryStuff",
                "TestHelpers",
                "UniqueIdentifierGenerator",
            ],
            path: "Tests/LocalQueueServerRunnerTests"
        ),
        .target(
            // MARK: Logging
            name: "Logging",
            dependencies: [
                "AtomicModels",
                "Extensions",
            ],
            path: "Sources/Logging"
        ),
        .target(
            // MARK: LoggingSetup
            name: "LoggingSetup",
            dependencies: [
                "FileSystem",
                "GraphiteClient",
                "IO",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "Models",
                "PathLib",
                "Sentry",
                "TemporaryStuff",
            ],
            path: "Sources/LoggingSetup"
        ),
        .testTarget(
            // MARK: LoggingTests
            name: "LoggingTests",
            dependencies: [
                "Logging",
                "TemporaryStuff",
            ],
            path: "Tests/LoggingTests"
        ),
        .target(
            // MARK: Metrics
            name: "Metrics",
            dependencies: [
            ],
            path: "Sources/Metrics"
        ),
        .testTarget(
            // MARK: MetricsTests
            name: "MetricsTests",
            dependencies: [
                "Metrics",
            ],
            path: "Tests/MetricsTests"
        ),
        .target(
            // MARK: Models
            name: "Models",
            dependencies: [
            ],
            path: "Sources/Models"
        ),
        .target(
            // MARK: ModelsTestHelpers
            name: "ModelsTestHelpers",
            dependencies: [
                "Models",
                "ScheduleStrategy",
            ],
            path: "Tests/ModelsTestHelpers"
        ),
        .testTarget(
            // MARK: ModelsTests
            name: "ModelsTests",
            dependencies: [
                "Models",
                "ModelsTestHelpers",
            ],
            path: "Tests/ModelsTests"
        ),
        .target(
            // MARK: PathLib
            name: "PathLib",
            dependencies: [
            ],
            path: "Sources/PathLib"
        ),
        .testTarget(
            // MARK: PathLibTests
            name: "PathLibTests",
            dependencies: [
                "PathLib",
            ],
            path: "Tests/PathLibTests"
        ),
        .target(
            // MARK: Plugin
            name: "Plugin",
            dependencies: [
                "DateProvider",
                "EventBus",
                "FileSystem",
                "JSONStream",
                "Logging",
                "LoggingSetup",
                "Models",
                "PluginSupport",
                "Starscream",
                "SynchronousWaiter",
            ],
            path: "Sources/Plugin"
        ),
        .target(
            // MARK: PluginManager
            name: "PluginManager",
            dependencies: [
                "EventBus",
                "Extensions",
                "LocalHostDeterminer",
                "Logging",
                "Models",
                "PathLib",
                "PluginSupport",
                "ProcessController",
                "ResourceLocationResolver",
                "Swifter",
                "SynchronousWaiter",
            ],
            path: "Sources/PluginManager"
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
                "FileSystem",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "PluginManager",
                "PluginSupport",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "ResourceLocation",
                "ResourceLocationResolverTestHelpers",
                "TemporaryStuff",
                "TestHelpers",
            ],
            path: "Tests/PluginManagerTests"
        ),
        .target(
            // MARK: PluginSupport
            name: "PluginSupport",
            dependencies: [
                "TypedResourceLocation",
            ],
            path: "Sources/PluginSupport"
        ),
        .target(
            // MARK: PortDeterminer
            name: "PortDeterminer",
            dependencies: [
                "Logging",
                "Swifter",
            ],
            path: "Sources/PortDeterminer"
        ),
        .testTarget(
            // MARK: PortDeterminerTests
            name: "PortDeterminerTests",
            dependencies: [
                "PortDeterminer",
                "Swifter",
            ],
            path: "Tests/PortDeterminerTests"
        ),
        .target(
            // MARK: ProcessController
            name: "ProcessController",
            dependencies: [
                "Extensions",
                "FileSystem",
                "Logging",
                "PathLib",
                "Timer",
            ],
            path: "Sources/ProcessController"
        ),
        .target(
            // MARK: ProcessControllerTestHelpers
            name: "ProcessControllerTestHelpers",
            dependencies: [
                "ProcessController",
                "SynchronousWaiter",
            ],
            path: "Tests/ProcessControllerTestHelpers"
        ),
        .testTarget(
            // MARK: ProcessControllerTests
            name: "ProcessControllerTests",
            dependencies: [
                "Extensions",
                "FileSystem",
                "PathLib",
                "ProcessController",
                "TemporaryStuff",
                "TestHelpers",
            ],
            path: "Tests/ProcessControllerTests"
        ),
        .target(
            // MARK: QueueClient
            name: "QueueClient",
            dependencies: [
                "AtomicModels",
                "DistWorkerModels",
                "Extensions",
                "Logging",
                "Models",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RequestSender",
                "ScheduleStrategy",
                "SynchronousWaiter",
            ],
            path: "Sources/QueueClient"
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
                "QueueClient",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RESTInterfaces",
                "RESTMethods",
                "RequestSender",
                "RequestSenderTestHelpers",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "Swifter",
                "SynchronousWaiter",
                "TestHelpers",
            ],
            path: "Tests/QueueClientTests"
        ),
        .target(
            // MARK: QueueCommunication
            name: "QueueCommunication",
            dependencies: [
                "AtomicModels",
                "Deployer",
                "Logging",
                "Models",
                "RESTMethods",
                "RemotePortDeterminer",
                "RequestSender",
                "Timer",
            ],
            path: "Sources/QueueCommunication"
        ),
        .target(
            // MARK: QueueCommunicationTestHelpers
            name: "QueueCommunicationTestHelpers",
            dependencies: [
                "Deployer",
                "Models",
                "QueueCommunication",
                "TestHelpers",
            ],
            path: "Tests/QueueCommunicationTestHelpers"
        ),
        .testTarget(
            // MARK: QueueCommunicationTests
            name: "QueueCommunicationTests",
            dependencies: [
                "Deployer",
                "DeployerTestHelpers",
                "Models",
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "RESTMethods",
                "RemotePortDeterminer",
                "RemotePortDeterminerTestHelpers",
                "RequestSenderTestHelpers",
                "TestHelpers",
            ],
            path: "Tests/QueueCommunicationTests"
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
            ],
            path: "Sources/QueueModels"
        ),
        .target(
            // MARK: QueueModelsTestHelpers
            name: "QueueModelsTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "Models",
                "ModelsTestHelpers",
                "PluginSupport",
                "QueueModels",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
            ],
            path: "Tests/QueueModelsTestHelpers"
        ),
        .testTarget(
            // MARK: QueueModelsTests
            name: "QueueModelsTests",
            dependencies: [
                "QueueModels",
            ],
            path: "Tests/QueueModelsTests"
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
                "Deployer",
                "DistWorkerModels",
                "EventBus",
                "Extensions",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "Models",
                "PortDeterminer",
                "QueueCommunication",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "RequestSender",
                "ScheduleStrategy",
                "Swifter",
                "SynchronousWaiter",
                "Timer",
                "UniqueIdentifierGenerator",
                "WorkerAlivenessProvider",
            ],
            path: "Sources/QueueServer"
        ),
        .target(
            // MARK: QueueServerTestHelpers
            name: "QueueServerTestHelpers",
            dependencies: [
                "Models",
                "QueueModels",
                "QueueServer",
                "ScheduleStrategy",
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
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
                "Extensions",
                "Models",
                "ModelsTestHelpers",
                "PortDeterminer",
                "QueueClient",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "QueueServer",
                "QueueServerTestHelpers",
                "RESTMethods",
                "RequestSender",
                "RequestSenderTestHelpers",
                "ScheduleStrategy",
                "Swifter",
                "SynchronousWaiter",
                "TestHelpers",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerAlivenessProviderTestHelpers",
            ],
            path: "Tests/QueueServerTests"
        ),
        .target(
            // MARK: RESTInterfaces
            name: "RESTInterfaces",
            dependencies: [
                "Models",
            ],
            path: "Sources/RESTInterfaces"
        ),
        .target(
            // MARK: RESTMethods
            name: "RESTMethods",
            dependencies: [
                "Deployer",
                "DistWorkerModels",
                "Models",
                "QueueModels",
                "RESTInterfaces",
                "RequestSender",
                "ScheduleStrategy",
            ],
            path: "Sources/RESTMethods"
        ),
        .target(
            // MARK: RESTServer
            name: "RESTServer",
            dependencies: [
                "AutomaticTermination",
                "Extensions",
                "Logging",
                "Models",
                "RESTInterfaces",
                "RESTMethods",
                "Swifter",
            ],
            path: "Sources/RESTServer"
        ),
        .testTarget(
            // MARK: RESTServerTests
            name: "RESTServerTests",
            dependencies: [
                "AutomaticTerminationTestHelpers",
                "Models",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "Swifter",
                "TestHelpers",
            ],
            path: "Tests/RESTServerTests"
        ),
        .target(
            // MARK: RemotePortDeterminer
            name: "RemotePortDeterminer",
            dependencies: [
                "AtomicModels",
                "Logging",
                "Models",
                "QueueClient",
                "RequestSender",
            ],
            path: "Sources/RemotePortDeterminer"
        ),
        .target(
            // MARK: RemotePortDeterminerTestHelpers
            name: "RemotePortDeterminerTestHelpers",
            dependencies: [
                "Models",
                "RemotePortDeterminer",
            ],
            path: "Tests/RemotePortDeterminerTestHelpers"
        ),
        .testTarget(
            // MARK: RemotePortDeterminerTests
            name: "RemotePortDeterminerTests",
            dependencies: [
                "Models",
                "PortDeterminer",
                "RESTInterfaces",
                "RESTMethods",
                "RemotePortDeterminer",
                "RequestSender",
                "RequestSenderTestHelpers",
                "Swifter",
            ],
            path: "Tests/RemotePortDeterminerTests"
        ),
        .target(
            // MARK: RequestSender
            name: "RequestSender",
            dependencies: [
                "Extensions",
                "Logging",
                "Models",
            ],
            path: "Sources/RequestSender"
        ),
        .target(
            // MARK: RequestSenderTestHelpers
            name: "RequestSenderTestHelpers",
            dependencies: [
                "Models",
                "RequestSender",
            ],
            path: "Tests/RequestSenderTestHelpers"
        ),
        .testTarget(
            // MARK: RequestSenderTests
            name: "RequestSenderTests",
            dependencies: [
                "Extensions",
                "Models",
                "ModelsTestHelpers",
                "RequestSender",
                "RequestSenderTestHelpers",
                "Swifter",
            ],
            path: "Tests/RequestSenderTests"
        ),
        .target(
            // MARK: ResourceLocation
            name: "ResourceLocation",
            dependencies: [
            ],
            path: "Sources/ResourceLocation"
        ),
        .target(
            // MARK: ResourceLocationResolver
            name: "ResourceLocationResolver",
            dependencies: [
                "AtomicModels",
                "Extensions",
                "FileCache",
                "Logging",
                "Models",
                "ProcessController",
                "ResourceLocation",
                "SynchronousWaiter",
                "TypedResourceLocation",
                "URLResource",
            ],
            path: "Sources/ResourceLocationResolver"
        ),
        .target(
            // MARK: ResourceLocationResolverTestHelpers
            name: "ResourceLocationResolverTestHelpers",
            dependencies: [
                "Models",
                "PathLib",
                "ResourceLocation",
                "ResourceLocationResolver",
            ],
            path: "Tests/ResourceLocationResolverTestHelpers"
        ),
        .testTarget(
            // MARK: ResourceLocationResolverTests
            name: "ResourceLocationResolverTests",
            dependencies: [
                "FileCache",
                "FileSystem",
                "Logging",
                "Models",
                "PathLib",
                "ProcessController",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Swifter",
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestHelpers",
                "URLResource",
            ],
            path: "Tests/ResourceLocationResolverTests"
        ),
        .testTarget(
            // MARK: ResourceLocationTests
            name: "ResourceLocationTests",
            dependencies: [
                "ResourceLocation",
                "TemporaryStuff",
            ],
            path: "Tests/ResourceLocationTests"
        ),
        .target(
            // MARK: Runner
            name: "Runner",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirLocator",
                "EventBus",
                "Extensions",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "Models",
                "PathLib",
                "PluginManager",
                "ProcessController",
                "ResourceLocationResolver",
                "RunnerModels",
                "SimulatorPoolModels",
                "TemporaryStuff",
                "TestsWorkingDirectorySupport",
            ],
            path: "Sources/Runner"
        ),
        .target(
            // MARK: RunnerModels
            name: "RunnerModels",
            dependencies: [
                "BuildArtifacts",
                "Models",
                "PluginSupport",
                "SimulatorPoolModels",
                "TypedResourceLocation",
            ],
            path: "Sources/RunnerModels"
        ),
        .target(
            // MARK: RunnerTestHelpers
            name: "RunnerTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirLocator",
                "Models",
                "ProcessController",
                "Runner",
                "RunnerModels",
                "SimulatorPoolModels",
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
                "EventBus",
                "Extensions",
                "Models",
                "ModelsTestHelpers",
                "PluginManagerTestHelpers",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "TestHelpers",
            ],
            path: "Tests/RunnerTests"
        ),
        .target(
            // MARK: SSHDeployer
            name: "SSHDeployer",
            dependencies: [
                "Deployer",
                "Extensions",
                "Logging",
                "Models",
                "PathLib",
                "ProcessController",
                "Shout",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/SSHDeployer"
        ),
        .testTarget(
            // MARK: SSHDeployerTests
            name: "SSHDeployerTests",
            dependencies: [
                "Deployer",
                "Models",
                "PathLib",
                "ProcessControllerTestHelpers",
                "SSHDeployer",
                "TemporaryStuff",
                "TestHelpers",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/SSHDeployerTests"
        ),
        .target(
            // MARK: ScheduleStrategy
            name: "ScheduleStrategy",
            dependencies: [
                "BuildArtifacts",
                "Extensions",
                "Logging",
                "Models",
                "PluginSupport",
                "QueueModels",
                "RunnerModels",
                "SimulatorPoolModels",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/ScheduleStrategy"
        ),
        .testTarget(
            // MARK: ScheduleStrategyTests
            name: "ScheduleStrategyTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
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
            ],
            path: "Tests/ScheduleStrategyTests"
        ),
        .target(
            // MARK: Scheduler
            name: "Scheduler",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirLocator",
                "EventBus",
                "Extensions",
                "ListeningSemaphore",
                "LocalHostDeterminer",
                "Logging",
                "Models",
                "PluginManager",
                "PluginSupport",
                "QueueModels",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "ScheduleStrategy",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SynchronousWaiter",
                "TemporaryStuff",
            ],
            path: "Sources/Scheduler"
        ),
        .target(
            // MARK: Sentry
            name: "Sentry",
            dependencies: [
            ],
            path: "Sources/Sentry"
        ),
        .testTarget(
            // MARK: SentryTests
            name: "SentryTests",
            dependencies: [
                "Sentry",
            ],
            path: "Tests/SentryTests"
        ),
        .target(
            // MARK: SignalHandling
            name: "SignalHandling",
            dependencies: [
                "Models",
                "Signals",
            ],
            path: "Sources/SignalHandling"
        ),
        .testTarget(
            // MARK: SignalHandlingTests
            name: "SignalHandlingTests",
            dependencies: [
                "SignalHandling",
                "Signals",
            ],
            path: "Tests/SignalHandlingTests"
        ),
        .target(
            // MARK: SimulatorPool
            name: "SimulatorPool",
            dependencies: [
                "AtomicModels",
                "AutomaticTermination",
                "DeveloperDirLocator",
                "Extensions",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "Models",
                "PathLib",
                "ResourceLocationResolver",
                "RunnerModels",
                "SimulatorPoolModels",
                "SynchronousWaiter",
                "TemporaryStuff",
            ],
            path: "Sources/SimulatorPool"
        ),
        .target(
            // MARK: SimulatorPoolModels
            name: "SimulatorPoolModels",
            dependencies: [
                "Extensions",
                "Models",
                "PathLib",
                "ResourceLocation",
                "TypedResourceLocation",
            ],
            path: "Sources/SimulatorPoolModels"
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
                "DeveloperDirLocator",
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
            ],
            path: "Tests/SimulatorPoolTests"
        ),
        .target(
            // MARK: SimulatorVideoRecorder
            name: "SimulatorVideoRecorder",
            dependencies: [
                "Logging",
                "Models",
                "PathLib",
                "ProcessController",
            ],
            path: "Sources/SimulatorVideoRecorder"
        ),
        .target(
            // MARK: SynchronousWaiter
            name: "SynchronousWaiter",
            dependencies: [
                "Logging",
            ],
            path: "Sources/SynchronousWaiter"
        ),
        .testTarget(
            // MARK: SynchronousWaiterTests
            name: "SynchronousWaiterTests",
            dependencies: [
                "SynchronousWaiter",
                "TestHelpers",
            ],
            path: "Tests/SynchronousWaiterTests"
        ),
        .target(
            // MARK: TemporaryStuff
            name: "TemporaryStuff",
            dependencies: [
                "PathLib",
            ],
            path: "Sources/TemporaryStuff"
        ),
        .testTarget(
            // MARK: TemporaryStuffTests
            name: "TemporaryStuffTests",
            dependencies: [
                "PathLib",
                "TemporaryStuff",
            ],
            path: "Tests/TemporaryStuffTests"
        ),
        .target(
            // MARK: TestArgFile
            name: "TestArgFile",
            dependencies: [
                "BuildArtifacts",
                "Models",
                "PluginSupport",
                "QueueModels",
                "RunnerModels",
                "ScheduleStrategy",
                "SimulatorPoolModels",
            ],
            path: "Sources/TestArgFile"
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
            ],
            path: "Tests/TestArgFileTests"
        ),
        .target(
            // MARK: TestDiscovery
            name: "TestDiscovery",
            dependencies: [
                "AppleTools",
                "AtomicModels",
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
            ],
            path: "Sources/TestDiscovery"
        ),
        .testTarget(
            // MARK: TestDiscoveryTests
            name: "TestDiscoveryTests",
            dependencies: [
                "AppleTools",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "FileCache",
                "FileSystem",
                "Logging",
                "Models",
                "ModelsTestHelpers",
                "PathLib",
                "PluginManagerTestHelpers",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "RequestSender",
                "RequestSenderTestHelpers",
                "ResourceLocation",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "TestDiscovery",
                "TestHelpers",
                "URLResource",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/TestDiscoveryTests"
        ),
        .target(
            // MARK: TestHelpers
            name: "TestHelpers",
            dependencies: [
            ],
            path: "Tests/TestHelpers"
        ),
        .target(
            // MARK: TestRunner
            name: "TestRunner",
            dependencies: [
            ],
            path: "Sources/TestRunner"
        ),
        .target(
            // MARK: TestingFakeFbxctest
            name: "TestingFakeFbxctest",
            dependencies: [
                "Extensions",
            ],
            path: "Sources/TestingFakeFbxctest"
        ),
        .target(
            // MARK: TestingPlugin
            name: "TestingPlugin",
            dependencies: [
                "DateProvider",
                "EventBus",
                "FileSystem",
                "Logging",
                "LoggingSetup",
                "Models",
                "Plugin",
            ],
            path: "Sources/TestingPlugin"
        ),
        .target(
            // MARK: TestsWorkingDirectorySupport
            name: "TestsWorkingDirectorySupport",
            dependencies: [
                "Models",
                "PathLib",
            ],
            path: "Sources/TestsWorkingDirectorySupport"
        ),
        .target(
            // MARK: Timer
            name: "Timer",
            dependencies: [
            ],
            path: "Sources/Timer"
        ),
        .target(
            // MARK: TypedResourceLocation
            name: "TypedResourceLocation",
            dependencies: [
                "ResourceLocation",
            ],
            path: "Sources/TypedResourceLocation"
        ),
        .target(
            // MARK: URLResource
            name: "URLResource",
            dependencies: [
                "AtomicModels",
                "FileCache",
                "Logging",
                "Models",
                "SynchronousWaiter",
            ],
            path: "Sources/URLResource"
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
            ],
            path: "Tests/URLResourceTests"
        ),
        .target(
            // MARK: UniqueIdentifierGenerator
            name: "UniqueIdentifierGenerator",
            dependencies: [
            ],
            path: "Sources/UniqueIdentifierGenerator"
        ),
        .target(
            // MARK: UniqueIdentifierGeneratorTestHelpers
            name: "UniqueIdentifierGeneratorTestHelpers",
            dependencies: [
                "UniqueIdentifierGenerator",
            ],
            path: "Tests/UniqueIdentifierGeneratorTestHelpers"
        ),
        .target(
            // MARK: WorkerAlivenessProvider
            name: "WorkerAlivenessProvider",
            dependencies: [
                "DateProvider",
                "Logging",
                "Models",
            ],
            path: "Sources/WorkerAlivenessProvider"
        ),
        .target(
            // MARK: WorkerAlivenessProviderTestHelpers
            name: "WorkerAlivenessProviderTestHelpers",
            dependencies: [
                "DateProvider",
                "DateProviderTestHelpers",
                "Models",
                "WorkerAlivenessProvider",
            ],
            path: "Tests/WorkerAlivenessProviderTestHelpers"
        ),
        .testTarget(
            // MARK: WorkerAlivenessProviderTests
            name: "WorkerAlivenessProviderTests",
            dependencies: [
                "DateProviderTestHelpers",
                "Models",
                "WorkerAlivenessProvider",
                "WorkerAlivenessProviderTestHelpers",
            ],
            path: "Tests/WorkerAlivenessProviderTests"
        ),
        .target(
            // MARK: fbxctest
            name: "fbxctest",
            dependencies: [
                "AtomicModels",
                "BuildArtifacts",
                "DeveloperDirLocator",
                "JSONStream",
                "LocalHostDeterminer",
                "Logging",
                "Models",
                "PathLib",
                "ProcessController",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                "TemporaryStuff",
                "Timer",
            ],
            path: "Sources/fbxctest"
        ),
        .testTarget(
            // MARK: fbxctestTests
            name: "fbxctestTests",
            dependencies: [
                "BuildArtifactsTestHelpers",
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
            ],
            path: "Tests/fbxctestTests"
        ),
    ]
)
