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
                "Logging",
                "Plugin",
            ]
        ),
        .library(
            name: "EmceeCommunications",
            targets: [
                "PortDeterminer",
                "QueueClient",
                "QueueCommunication",
                "RemotePortDeterminer",
                "RequestSender",
            ]
        ),
        .library(
            name: "EmceeInterfaces",
            targets: [
                "BuildArtifacts",
                "DeveloperDirModels",
                "EmceeVersion",
                "FileSystem",
                "PathLib",
                "PluginSupport",
                "QueueModels",
                "ResourceLocation",
                "ResourceLocationResolver",
                "RunnerModels",
                "SimulatorPoolModels",
                "SimulatorVideoRecorder",
                "SocketModels",
                "TestArgFile",
                "TestDiscovery",
                "TypedResourceLocation",
                "WorkerAlivenessModels",
                "WorkerCapabilitiesModels",
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
        .package(url: "https://github.com/jakeheis/Shout.git", .exact("0.5.4")),
    ],
    targets: [
        .target(
            // MARK: AppleTools
            name: "AppleTools",
            dependencies: [
                "AtomicModels",
                "BuildArtifacts",
                "DateProvider",
                "DeveloperDirLocator",
                "Logging",
                "PathLib",
                "PlistLib",
                "ProcessController",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                "TemporaryStuff",
                "XCTestJsonCodable",
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
                "DeveloperDirModels",
                "FileCache",
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
                "Logging",
                "QueueModels",
                "RunnerModels",
                "Types",
                "WorkerCapabilitiesModels",
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
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "TestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
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
                "QueueModels",
                "RunnerModels",
                "Types",
                "UniqueIdentifierGenerator",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
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
                "QueueModels",
                "QueueModelsTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerCapabilitiesModels",
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
                "QueueModels",
                "QueueModelsTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "TestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerCapabilitiesModels",
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
            ],
            path: "Tests/BuildArtifactsTestHelpers"
        ),
        .target(
            // MARK: ChromeTracing
            name: "ChromeTracing",
            dependencies: [
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
                "Logging",
                "PathLib",
                "ProcessController",
                "QueueModels",
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
            ],
            path: "Tests/DeployerTestHelpers"
        ),
        .testTarget(
            // MARK: DeployerTests
            name: "DeployerTests",
            dependencies: [
                "Deployer",
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
                "DeveloperDirModels",
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
                "DeveloperDirModels",
                "PathLib",
            ],
            path: "Tests/DeveloperDirLocatorTestHelpers"
        ),
        .testTarget(
            // MARK: DeveloperDirLocatorTests
            name: "DeveloperDirLocatorTests",
            dependencies: [
                "DeveloperDirLocator",
                "PathLib",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "TemporaryStuff",
                "TestHelpers",
            ],
            path: "Tests/DeveloperDirLocatorTests"
        ),
        .target(
            // MARK: DeveloperDirModels
            name: "DeveloperDirModels",
            dependencies: [
            ],
            path: "Sources/DeveloperDirModels"
        ),
        .target(
            // MARK: DistDeployer
            name: "DistDeployer",
            dependencies: [
                "Deployer",
                "LaunchdUtils",
                "Logging",
                "PathLib",
                "ProcessController",
                "QueueModels",
                "SSHDeployer",
                "SocketModels",
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
                "PathLib",
                "QueueModels",
                "ResourceLocationResolver",
                "SocketModels",
                "TemporaryStuff",
            ],
            path: "Tests/DistDeployerTests"
        ),
        .target(
            // MARK: DistWorker
            name: "DistWorker",
            dependencies: [
                "AtomicModels",
                "AutomaticTermination",
                "CountedSet",
                "DateProvider",
                "DeveloperDirLocator",
                "DistWorkerModels",
                "EventBus",
                "FileSystem",
                "LocalHostDeterminer",
                "Logging",
                "LoggingSetup",
                "PathLib",
                "PluginManager",
                "QueueClient",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "RequestSender",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "Scheduler",
                "SimulatorPool",
                "SocketModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "Timer",
                "Types",
                "UniqueIdentifierGenerator",
                "WorkerCapabilities",
            ],
            path: "Sources/DistWorker"
        ),
        .target(
            // MARK: DistWorkerModels
            name: "DistWorkerModels",
            dependencies: [
                "LoggingSetup",
                "QueueModels",
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
                "QueueModels",
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
                "QueueModels",
                "RequestSender",
                "RunnerModels",
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
                "DeveloperDirModels",
                "DistDeployer",
                "DistWorker",
                "DistWorkerModels",
                "EmceeVersion",
                "EventBus",
                "FileCache",
                "FileSystem",
                "JunitReporting",
                "LocalHostDeterminer",
                "LocalQueueServerRunner",
                "Logging",
                "LoggingSetup",
                "Metrics",
                "PathLib",
                "PluginManager",
                "PortDeterminer",
                "ProcessController",
                "QueueClient",
                "QueueCommunication",
                "QueueModels",
                "QueueServer",
                "RESTMethods",
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
                "SocketModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestArgFile",
                "TestDiscovery",
                "TypedResourceLocation",
                "Types",
                "URLResource",
                "UniqueIdentifierGenerator",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
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
                "DateProviderTestHelpers",
                "EmceeLib",
                "FileSystem",
                "FileSystemTestHelpers",
                "PathLib",
                "ProcessControllerTestHelpers",
                "QueueModels",
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
            // MARK: EmceeVersion
            name: "EmceeVersion",
            dependencies: [
                "QueueModels",
            ],
            path: "Sources/EmceeVersion"
        ),
        .target(
            // MARK: EventBus
            name: "EventBus",
            dependencies: [
                "Logging",
                "RunnerModels",
            ],
            path: "Sources/EventBus"
        ),
        .testTarget(
            // MARK: EventBusTests
            name: "EventBusTests",
            dependencies: [
                "EventBus",
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
                "DateProvider",
                "Extensions",
                "FileLock",
                "FileSystem",
                "PathLib",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/FileCache"
        ),
        .testTarget(
            // MARK: FileCacheTests
            name: "FileCacheTests",
            dependencies: [
                "DateProvider",
                "FileCache",
                "FileSystem",
                "PathLib",
                "TemporaryStuff",
                "TestHelpers",
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
                "DateProvider",
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
                "Deployer",
                "DistDeployer",
                "DistWorkerModels",
                "FileLock",
                "LocalHostDeterminer",
                "Logging",
                "LoggingSetup",
                "ProcessController",
                "QueueCommunication",
                "QueueModels",
                "QueueServer",
                "RemotePortDeterminer",
                "SocketModels",
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
                "DistDeployer",
                "LocalQueueServerRunner",
                "ProcessControllerTestHelpers",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueServer",
                "QueueServerTestHelpers",
                "RemotePortDeterminer",
                "RemotePortDeterminerTestHelpers",
                "ScheduleStrategy",
                "SocketModels",
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
                "DateProvider",
                "FileSystem",
                "GraphiteClient",
                "IO",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "PathLib",
                "QueueModels",
                "Sentry",
                "SocketModels",
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
        .target(
            // MARK: MetricsTestHelpers
            name: "MetricsTestHelpers",
            dependencies: [
                "Metrics",
            ],
            path: "Tests/MetricsTestHelpers"
        ),
        .testTarget(
            // MARK: MetricsTests
            name: "MetricsTests",
            dependencies: [
                "Metrics",
                "MetricsTestHelpers",
            ],
            path: "Tests/MetricsTests"
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
            // MARK: PlistLib
            name: "PlistLib",
            dependencies: [
            ],
            path: "Sources/PlistLib"
        ),
        .testTarget(
            // MARK: PlistLibTests
            name: "PlistLibTests",
            dependencies: [
                "PlistLib",
                "TestHelpers",
            ],
            path: "Tests/PlistLibTests"
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
                "FileSystem",
                "LocalHostDeterminer",
                "Logging",
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
                "FileSystem",
                "PluginManager",
                "PluginSupport",
            ],
            path: "Tests/PluginManagerTestHelpers"
        ),
        .testTarget(
            // MARK: PluginManagerTests
            name: "PluginManagerTests",
            dependencies: [
                "DateProvider",
                "EventBus",
                "FileSystem",
                "PathLib",
                "PluginManager",
                "PluginSupport",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "ResourceLocation",
                "ResourceLocationResolverTestHelpers",
                "RunnerTestHelpers",
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
                "SocketModels",
                "Swifter",
            ],
            path: "Sources/PortDeterminer"
        ),
        .testTarget(
            // MARK: PortDeterminerTests
            name: "PortDeterminerTests",
            dependencies: [
                "PortDeterminer",
                "SocketModels",
                "Swifter",
            ],
            path: "Tests/PortDeterminerTests"
        ),
        .target(
            // MARK: ProcessController
            name: "ProcessController",
            dependencies: [
                "AtomicModels",
                "DateProvider",
                "FileSystem",
                "Logging",
                "LoggingSetup",
                "PathLib",
                "SignalHandling",
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
                "TemporaryStuff",
            ],
            path: "Tests/ProcessControllerTestHelpers"
        ),
        .testTarget(
            // MARK: ProcessControllerTests
            name: "ProcessControllerTests",
            dependencies: [
                "DateProvider",
                "FileSystem",
                "PathLib",
                "ProcessController",
                "SignalHandling",
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
                "Logging",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RequestSender",
                "ScheduleStrategy",
                "SocketModels",
                "SynchronousWaiter",
                "Types",
                "WorkerAlivenessModels",
                "WorkerCapabilitiesModels",
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
                "QueueClient",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RESTInterfaces",
                "RESTMethods",
                "RequestSender",
                "RequestSenderTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "SocketModels",
                "Swifter",
                "SynchronousWaiter",
                "TestHelpers",
                "Types",
                "WorkerAlivenessModels",
            ],
            path: "Tests/QueueClientTests"
        ),
        .target(
            // MARK: QueueCommunication
            name: "QueueCommunication",
            dependencies: [
                "AtomicModels",
                "DateProvider",
                "Deployer",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "QueueModels",
                "RESTMethods",
                "RemotePortDeterminer",
                "RequestSender",
                "SocketModels",
                "Timer",
                "Types",
            ],
            path: "Sources/QueueCommunication"
        ),
        .target(
            // MARK: QueueCommunicationTestHelpers
            name: "QueueCommunicationTestHelpers",
            dependencies: [
                "Deployer",
                "DeployerTestHelpers",
                "QueueCommunication",
                "QueueModels",
                "SocketModels",
                "TestHelpers",
                "Types",
            ],
            path: "Tests/QueueCommunicationTestHelpers"
        ),
        .testTarget(
            // MARK: QueueCommunicationTests
            name: "QueueCommunicationTests",
            dependencies: [
                "DateProvider",
                "DateProviderTestHelpers",
                "Deployer",
                "DeployerTestHelpers",
                "Metrics",
                "MetricsTestHelpers",
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "RESTMethods",
                "RemotePortDeterminer",
                "RemotePortDeterminerTestHelpers",
                "RequestSenderTestHelpers",
                "SocketModels",
                "TestHelpers",
            ],
            path: "Tests/QueueCommunicationTests"
        ),
        .target(
            // MARK: QueueModels
            name: "QueueModels",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirModels",
                "PluginSupport",
                "RunnerModels",
                "SimulatorPoolModels",
                "SocketModels",
                "Types",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/QueueModels"
        ),
        .target(
            // MARK: QueueModelsTestHelpers
            name: "QueueModelsTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "DeveloperDirModels",
                "PluginSupport",
                "QueueModels",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "Types",
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/QueueModelsTestHelpers"
        ),
        .testTarget(
            // MARK: QueueModelsTests
            name: "QueueModelsTests",
            dependencies: [
                "QueueModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
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
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "PortDeterminer",
                "QueueCommunication",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "RequestSender",
                "RunnerModels",
                "ScheduleStrategy",
                "SocketModels",
                "Swifter",
                "SynchronousWaiter",
                "Timer",
                "Types",
                "UniqueIdentifierGenerator",
                "WorkerAlivenessModels",
                "WorkerAlivenessProvider",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/QueueServer"
        ),
        .target(
            // MARK: QueueServerTestHelpers
            name: "QueueServerTestHelpers",
            dependencies: [
                "QueueModels",
                "QueueServer",
                "ScheduleStrategy",
                "SocketModels",
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
                "DeployerTestHelpers",
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
                "PortDeterminer",
                "QueueClient",
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "QueueServer",
                "QueueServerTestHelpers",
                "RESTMethods",
                "RemotePortDeterminerTestHelpers",
                "RequestSender",
                "RequestSenderTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "ScheduleStrategy",
                "SimulatorPoolTestHelpers",
                "SocketModels",
                "Swifter",
                "SynchronousWaiter",
                "TestHelpers",
                "Types",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessModels",
                "WorkerAlivenessProvider",
            ],
            path: "Tests/QueueServerTests"
        ),
        .target(
            // MARK: RESTInterfaces
            name: "RESTInterfaces",
            dependencies: [
                "QueueModels",
            ],
            path: "Sources/RESTInterfaces"
        ),
        .target(
            // MARK: RESTMethods
            name: "RESTMethods",
            dependencies: [
                "Deployer",
                "DistWorkerModels",
                "QueueModels",
                "RESTInterfaces",
                "RequestSender",
                "ScheduleStrategy",
                "SocketModels",
                "WorkerAlivenessModels",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/RESTMethods"
        ),
        .target(
            // MARK: RESTServer
            name: "RESTServer",
            dependencies: [
                "AutomaticTermination",
                "Logging",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "SocketModels",
                "Swifter",
            ],
            path: "Sources/RESTServer"
        ),
        .testTarget(
            // MARK: RESTServerTests
            name: "RESTServerTests",
            dependencies: [
                "AutomaticTerminationTestHelpers",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "SocketModels",
                "Swifter",
                "TestHelpers",
                "Types",
            ],
            path: "Tests/RESTServerTests"
        ),
        .target(
            // MARK: RemotePortDeterminer
            name: "RemotePortDeterminer",
            dependencies: [
                "AtomicModels",
                "Logging",
                "QueueClient",
                "QueueModels",
                "RequestSender",
                "SocketModels",
                "Types",
            ],
            path: "Sources/RemotePortDeterminer"
        ),
        .target(
            // MARK: RemotePortDeterminerTestHelpers
            name: "RemotePortDeterminerTestHelpers",
            dependencies: [
                "QueueModels",
                "RemotePortDeterminer",
                "SocketModels",
            ],
            path: "Tests/RemotePortDeterminerTestHelpers"
        ),
        .testTarget(
            // MARK: RemotePortDeterminerTests
            name: "RemotePortDeterminerTests",
            dependencies: [
                "PortDeterminer",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RemotePortDeterminer",
                "RequestSender",
                "RequestSenderTestHelpers",
                "SocketModels",
                "Swifter",
            ],
            path: "Tests/RemotePortDeterminerTests"
        ),
        .target(
            // MARK: RequestSender
            name: "RequestSender",
            dependencies: [
                "Logging",
                "SocketModels",
                "Types",
            ],
            path: "Sources/RequestSender"
        ),
        .target(
            // MARK: RequestSenderTestHelpers
            name: "RequestSenderTestHelpers",
            dependencies: [
                "RequestSender",
                "SocketModels",
                "Types",
            ],
            path: "Tests/RequestSenderTestHelpers"
        ),
        .testTarget(
            // MARK: RequestSenderTests
            name: "RequestSenderTests",
            dependencies: [
                "RequestSender",
                "RequestSenderTestHelpers",
                "SocketModels",
                "Swifter",
                "Types",
            ],
            path: "Tests/RequestSenderTests"
        ),
        .target(
            // MARK: ResourceLocation
            name: "ResourceLocation",
            dependencies: [
                "PathLib",
            ],
            path: "Sources/ResourceLocation"
        ),
        .target(
            // MARK: ResourceLocationResolver
            name: "ResourceLocationResolver",
            dependencies: [
                "AtomicModels",
                "FileCache",
                "FileSystem",
                "Logging",
                "PathLib",
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
                "DateProvider",
                "FileCache",
                "FileSystem",
                "Logging",
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
                "AtomicModels",
                "BuildArtifacts",
                "DateProvider",
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EventBus",
                "FileSystem",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "PathLib",
                "PluginManager",
                "ProcessController",
                "QueueModels",
                "ResourceLocationResolver",
                "RunnerModels",
                "SimulatorPoolModels",
                "TemporaryStuff",
                "TestsWorkingDirectorySupport",
                "Timer",
            ],
            path: "Sources/Runner"
        ),
        .target(
            // MARK: RunnerModels
            name: "RunnerModels",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirModels",
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
                "DeveloperDirModels",
                "Logging",
                "ProcessController",
                "Runner",
                "RunnerModels",
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
                "DateProviderTestHelpers",
                "DeveloperDirLocatorTestHelpers",
                "EventBus",
                "FileSystemTestHelpers",
                "Logging",
                "Metrics",
                "MetricsTestHelpers",
                "PathLib",
                "PluginManagerTestHelpers",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "QueueModels",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "SynchronousWaiter",
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
                "Logging",
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
                "DeveloperDirModels",
                "Logging",
                "PluginSupport",
                "QueueModels",
                "RunnerModels",
                "SimulatorPoolModels",
                "Types",
                "UniqueIdentifierGenerator",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/ScheduleStrategy"
        ),
        .testTarget(
            // MARK: ScheduleStrategyTests
            name: "ScheduleStrategyTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "PluginSupport",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "ScheduleStrategy",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TestHelpers",
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
                "DateProvider",
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EventBus",
                "FileSystem",
                "ListeningSemaphore",
                "LocalHostDeterminer",
                "Logging",
                "PluginManager",
                "PluginSupport",
                "ProcessController",
                "QueueModels",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "ScheduleStrategy",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "UniqueIdentifierGenerator",
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
                "Signals",
                "Types",
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
                "DateProvider",
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "LocalHostDeterminer",
                "Logging",
                "Metrics",
                "PathLib",
                "PlistLib",
                "ProcessController",
                "QueueModels",
                "ResourceLocationResolver",
                "RunnerModels",
                "SimulatorPoolModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "Types",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/SimulatorPool"
        ),
        .target(
            // MARK: SimulatorPoolModels
            name: "SimulatorPoolModels",
            dependencies: [
                "PathLib",
                "ResourceLocation",
                "TypedResourceLocation",
                "Types",
            ],
            path: "Sources/SimulatorPoolModels"
        ),
        .target(
            // MARK: SimulatorPoolTestHelpers
            name: "SimulatorPoolTestHelpers",
            dependencies: [
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                "PathLib",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                "TemporaryStuff",
                "Types",
            ],
            path: "Tests/SimulatorPoolTestHelpers"
        ),
        .testTarget(
            // MARK: SimulatorPoolTests
            name: "SimulatorPoolTests",
            dependencies: [
                "DateProviderTestHelpers",
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                "PathLib",
                "PlistLib",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "QueueModels",
                "ResourceLocationResolver",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/SimulatorPoolTests"
        ),
        .target(
            // MARK: SimulatorVideoRecorder
            name: "SimulatorVideoRecorder",
            dependencies: [
                "Logging",
                "PathLib",
                "ProcessController",
                "SimulatorPoolModels",
            ],
            path: "Sources/SimulatorVideoRecorder"
        ),
        .target(
            // MARK: SocketModels
            name: "SocketModels",
            dependencies: [
                "Types",
            ],
            path: "Sources/SocketModels"
        ),
        .testTarget(
            // MARK: SocketModelsTests
            name: "SocketModelsTests",
            dependencies: [
                "SocketModels",
            ],
            path: "Tests/SocketModelsTests"
        ),
        .target(
            // MARK: SynchronousWaiter
            name: "SynchronousWaiter",
            dependencies: [
                "AtomicModels",
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
                "DeveloperDirModels",
                "PluginSupport",
                "QueueModels",
                "RunnerModels",
                "ScheduleStrategy",
                "SimulatorPoolModels",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/TestArgFile"
        ),
        .testTarget(
            // MARK: TestArgFileTests
            name: "TestArgFileTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "PluginSupport",
                "ResourceLocation",
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
                "DateProvider",
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "FileSystem",
                "Logging",
                "Metrics",
                "PathLib",
                "PluginManager",
                "PluginSupport",
                "ProcessController",
                "QueueModels",
                "RequestSender",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SocketModels",
                "SynchronousWaiter",
                "TemporaryStuff",
                "TestArgFile",
                "Types",
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
                "DateProvider",
                "DateProviderTestHelpers",
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                "FileCache",
                "FileSystem",
                "FileSystemTestHelpers",
                "Logging",
                "PathLib",
                "PluginManagerTestHelpers",
                "ProcessController",
                "ProcessControllerTestHelpers",
                "QueueModels",
                "RequestSender",
                "RequestSenderTestHelpers",
                "ResourceLocation",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "SocketModels",
                "TemporaryStuff",
                "TestArgFile",
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
                "Plugin",
            ],
            path: "Sources/TestingPlugin"
        ),
        .target(
            // MARK: TestsWorkingDirectorySupport
            name: "TestsWorkingDirectorySupport",
            dependencies: [
                "PathLib",
                "RunnerModels",
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
            // MARK: Types
            name: "Types",
            dependencies: [
            ],
            path: "Sources/Types"
        ),
        .testTarget(
            // MARK: TypesTests
            name: "TypesTests",
            dependencies: [
                "Types",
            ],
            path: "Tests/TypesTests"
        ),
        .target(
            // MARK: URLResource
            name: "URLResource",
            dependencies: [
                "AtomicModels",
                "FileCache",
                "Logging",
                "PathLib",
                "SynchronousWaiter",
                "Types",
            ],
            path: "Sources/URLResource"
        ),
        .testTarget(
            // MARK: URLResourceTests
            name: "URLResourceTests",
            dependencies: [
                "DateProviderTestHelpers",
                "FileCache",
                "FileSystem",
                "PathLib",
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
            // MARK: WorkerAlivenessModels
            name: "WorkerAlivenessModels",
            dependencies: [
                "QueueModels",
            ],
            path: "Sources/WorkerAlivenessModels"
        ),
        .target(
            // MARK: WorkerAlivenessProvider
            name: "WorkerAlivenessProvider",
            dependencies: [
                "Logging",
                "QueueModels",
                "WorkerAlivenessModels",
            ],
            path: "Sources/WorkerAlivenessProvider"
        ),
        .testTarget(
            // MARK: WorkerAlivenessProviderTests
            name: "WorkerAlivenessProviderTests",
            dependencies: [
                "QueueModels",
                "WorkerAlivenessModels",
                "WorkerAlivenessProvider",
            ],
            path: "Tests/WorkerAlivenessProviderTests"
        ),
        .target(
            // MARK: WorkerCapabilities
            name: "WorkerCapabilities",
            dependencies: [
                "FileSystem",
                "Logging",
                "PathLib",
                "PlistLib",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/WorkerCapabilities"
        ),
        .target(
            // MARK: WorkerCapabilitiesModels
            name: "WorkerCapabilitiesModels",
            dependencies: [
                "Types",
            ],
            path: "Sources/WorkerCapabilitiesModels"
        ),
        .testTarget(
            // MARK: WorkerCapabilitiesTests
            name: "WorkerCapabilitiesTests",
            dependencies: [
                "FileSystem",
                "FileSystemTestHelpers",
                "PlistLib",
                "TemporaryStuff",
                "TestHelpers",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/WorkerCapabilitiesTests"
        ),
        .target(
            // MARK: XCTestJsonCodable
            name: "XCTestJsonCodable",
            dependencies: [
            ],
            path: "Sources/XCTestJsonCodable"
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
                "ProcessController",
                "ProcessControllerTestHelpers",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                "TemporaryStuff",
                "TestHelpers",
                "fbxctest",
            ],
            path: "Tests/fbxctestTests"
        ),
    ]
)
