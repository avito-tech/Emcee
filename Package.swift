// swift-tools-version:5.2
import PackageDescription
let package = Package(
    name: "EmceeTestRunner",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "Emcee", targets: ["EmceeBinary"]),
        .executable(name: "testing_plugin", targets: ["TestingPlugin"]),
        .library(name: "EmceePlugin", targets: ["EmceeLogging", "Plugin"]),
        .library(name: "EmceeCommunications", targets: ["PortDeterminer", "QueueClient", "QueueCommunication", "RemotePortDeterminer", "RequestSender"]),
        .library(name: "EmceeInterfaces", targets: ["BuildArtifacts", "DeveloperDirModels", "EmceeVersion", "PluginSupport", "QueueModels", "ResourceLocation", "ResourceLocationResolver", "RunnerModels", "SimulatorPoolModels", "SimulatorVideoRecorder", "TestArgFile", "TestDiscovery", "TestsWorkingDirectorySupport", "TypedResourceLocation", "WorkerAlivenessModels", "WorkerCapabilitiesModels", "XcodebuildTestRunnerConstants"]),
    ],
    dependencies: [
        .package(name: "CommandLineToolkit", url: "https://github.com/avito-tech/CommandLineToolkit.git", .exact("1.0.6")),
        .package(name: "CountedSet", url: "https://github.com/0x7fs/CountedSet", .branch("master")),
        .package(name: "OrderedSet", url: "https://github.com/Weebly/OrderedSet", .exact("5.0.0")),
        .package(name: "Shout", url: "https://github.com/jakeheis/Shout.git", .exact("0.5.4")),
        .package(name: "Starscream", url: "https://github.com/daltoniam/Starscream.git", .exact("3.0.6")),
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter.git", .exact("1.4.6")),
        .package(name: "swift-log", url: "https://github.com/apple/swift-log.git", .exact("1.4.1")),
    ],
    targets: [
        .target(
            name: "AppleTools",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "BuildArtifacts",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "ObservableFileReader",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "PlistLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "ResourceLocation",
                "ResourceLocationResolver",
                "ResultStream",
                "ResultStreamModels",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "XcodebuildTestRunnerConstants",
            ],
            path: "Sources/AppleTools"
        ),
        .target(
            name: "AppleToolsTestHelpers",
            dependencies: [
                "AppleTools",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "ResultStreamModels",
            ],
            path: "Tests/AppleToolsTestHelpers"
        ),
        .testTarget(
            name: "AppleToolsTests",
            dependencies: [
                "AppleTools",
                "AppleToolsTestHelpers",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                "EmceeTypes",
                "FileCache",
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueModelsTestHelpers",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "ResultStreamModels",
                "ResultStreamModelsTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "URLResource",
            ],
            path: "Tests/AppleToolsTests"
        ),
        .target(
            name: "ArgLib",
            dependencies: [
                .product(name: "OrderedSet", package: "OrderedSet"),
            ],
            path: "Sources/ArgLib"
        ),
        .testTarget(
            name: "ArgLibTests",
            dependencies: [
                "ArgLib",
            ],
            path: "Tests/ArgLibTests"
        ),
        .target(
            name: "AutomaticTermination",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeLogging",
                .product(name: "Timer", package: "CommandLineToolkit"),
            ],
            path: "Sources/AutomaticTermination"
        ),
        .target(
            name: "AutomaticTerminationTestHelpers",
            dependencies: [
                "AutomaticTermination",
            ],
            path: "Tests/AutomaticTerminationTestHelpers"
        ),
        .testTarget(
            name: "AutomaticTerminationTests",
            dependencies: [
                "AutomaticTermination",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
            ],
            path: "Tests/AutomaticTerminationTests"
        ),
        .target(
            name: "BalancingBucketQueue",
            dependencies: [
                "BucketQueue",
                "BucketQueueModels",
                .product(name: "CountedSet", package: "CountedSet"),
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "Extensions",
                "LocalHostDeterminer",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                "QueueModels",
                "RunnerModels",
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/BalancingBucketQueue"
        ),
        .testTarget(
            name: "BalancingBucketQueueTests",
            dependencies: [
                "BalancingBucketQueue",
                "BucketQueue",
                "BucketQueueModels",
                "BucketQueueTestHelpers",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "TestHistoryTestHelpers",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/BalancingBucketQueueTests"
        ),
        .target(
            name: "BucketQueue",
            dependencies: [
                "BucketQueueModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeLogging",
                "Extensions",
                "QueueModels",
                "RunnerModels",
                "TestHistoryModels",
                "TestHistoryTracker",
                .product(name: "Types", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/BucketQueue"
        ),
        .target(
            name: "BucketQueueModels",
            dependencies: [
                "EmceeLogging",
                "QueueModels",
            ],
            path: "Sources/BucketQueueModels"
        ),
        .target(
            name: "BucketQueueTestHelpers",
            dependencies: [
                "BucketQueue",
                "BucketQueueModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "QueueModels",
                "QueueModelsTestHelpers",
                "TestHistoryTestHelpers",
                "TestHistoryTracker",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/BucketQueueTestHelpers"
        ),
        .testTarget(
            name: "BucketQueueTests",
            dependencies: [
                "BucketQueue",
                "BucketQueueModels",
                "BucketQueueTestHelpers",
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DistWorkerModels",
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "TestHistoryTestHelpers",
                "TestHistoryTracker",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/BucketQueueTests"
        ),
        .target(
            name: "BuildArtifacts",
            dependencies: [
                "TypedResourceLocation",
            ],
            path: "Sources/BuildArtifacts"
        ),
        .target(
            name: "BuildArtifactsTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "ResourceLocation",
            ],
            path: "Tests/BuildArtifactsTestHelpers"
        ),
        .target(
            name: "ChromeTracing",
            dependencies: [
            ],
            path: "Sources/ChromeTracing"
        ),
        .target(
            name: "DI",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
            ],
            path: "Sources/DI"
        ),
        .testTarget(
            name: "DITests",
            dependencies: [
                "DI",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/DITests"
        ),
        .target(
            name: "Deployer",
            dependencies: [
                "EmceeLogging",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/Deployer"
        ),
        .target(
            name: "DeployerTestHelpers",
            dependencies: [
                "Deployer",
                .product(name: "PathLib", package: "CommandLineToolkit"),
            ],
            path: "Tests/DeployerTestHelpers"
        ),
        .testTarget(
            name: "DeployerTests",
            dependencies: [
                "Deployer",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/DeployerTests"
        ),
        .target(
            name: "DeveloperDirLocator",
            dependencies: [
                "DeveloperDirModels",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
            ],
            path: "Sources/DeveloperDirLocator"
        ),
        .target(
            name: "DeveloperDirLocatorTestHelpers",
            dependencies: [
                "DeveloperDirLocator",
                "DeveloperDirModels",
                .product(name: "PathLib", package: "CommandLineToolkit"),
            ],
            path: "Tests/DeveloperDirLocatorTestHelpers"
        ),
        .testTarget(
            name: "DeveloperDirLocatorTests",
            dependencies: [
                "DeveloperDirLocator",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
            ],
            path: "Tests/DeveloperDirLocatorTests"
        ),
        .target(
            name: "DeveloperDirModels",
            dependencies: [
            ],
            path: "Sources/DeveloperDirModels"
        ),
        .target(
            name: "DistDeployer",
            dependencies: [
                "Deployer",
                "EmceeLogging",
                .product(name: "LaunchdUtils", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                "SSHDeployer",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "TypedResourceLocation",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/DistDeployer"
        ),
        .testTarget(
            name: "DistDeployerTests",
            dependencies: [
                "Deployer",
                "DeployerTestHelpers",
                "DistDeployer",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "QueueModels",
                "ResourceLocationResolver",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
            ],
            path: "Tests/DistDeployerTests"
        ),
        .target(
            name: "DistWorker",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "AutomaticTermination",
                .product(name: "CountedSet", package: "CountedSet"),
                "DI",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DistWorkerModels",
                "EmceeLogging",
                "EventBus",
                "Extensions",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "LocalHostDeterminer",
                "LoggingSetup",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
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
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Timer", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "WorkerCapabilities",
            ],
            path: "Sources/DistWorker"
        ),
        .target(
            name: "DistWorkerModels",
            dependencies: [
                .product(name: "CLTExtensions", package: "CommandLineToolkit"),
                "LoggingSetup",
                "MetricsExtensions",
                "QueueModels",
                "RESTInterfaces",
            ],
            path: "Sources/DistWorkerModels"
        ),
        .target(
            name: "DistWorkerModelsTestHelpers",
            dependencies: [
                "DistWorkerModels",
                "LoggingSetup",
                "MetricsExtensions",
                "QueueModels",
            ],
            path: "Tests/DistWorkerModelsTestHelpers"
        ),
        .testTarget(
            name: "DistWorkerModelsTests",
            dependencies: [
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
            ],
            path: "Tests/DistWorkerModelsTests"
        ),
        .testTarget(
            name: "DistWorkerTests",
            dependencies: [
                "BuildArtifactsTestHelpers",
                "DistWorker",
                "MetricsExtensions",
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
            name: "EmceeBinary",
            dependencies: [
                "EmceeLib",
            ],
            path: "Sources/EmceeBinary"
        ),
        .target(
            name: "EmceeLib",
            dependencies: [
                "AppleTools",
                "ArgLib",
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "AutomaticTermination",
                "BucketQueue",
                "BuildArtifacts",
                "ChromeTracing",
                "DI",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "Deployer",
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "DistDeployer",
                "DistWorker",
                "DistWorkerModels",
                "EmceeLogging",
                "EmceeVersion",
                "EventBus",
                "Extensions",
                "FileCache",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "JunitReporting",
                "LocalHostDeterminer",
                "LocalQueueServerRunner",
                .product(name: "Logging", package: "swift-log"),
                "LoggingSetup",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginManager",
                "PortDeterminer",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueClient",
                "QueueCommunication",
                "QueueModels",
                "QueueServer",
                "QueueServerPortProvider",
                "RESTMethods",
                "RemotePortDeterminer",
                "RequestSender",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "ScheduleStrategy",
                "Scheduler",
                .product(name: "SignalHandling", package: "CommandLineToolkit"),
                "SimulatorPool",
                "SimulatorPoolModels",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TestArgFile",
                "TestDiscovery",
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "TypedResourceLocation",
                .product(name: "Types", package: "CommandLineToolkit"),
                "URLResource",
                "UniqueIdentifierGenerator",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/EmceeLib"
        ),
        .testTarget(
            name: "EmceeLibTests",
            dependencies: [
                "AppleTools",
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "EmceeLib",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                "LoggingSetup",
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueModels",
                "QueueModelsTestHelpers",
                "ResourceLocationResolverTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TestArgFile",
                "TestDiscovery",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "URLResource",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/EmceeLibTests"
        ),
        .target(
            name: "EmceeLogging",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeVersion",
                "Extensions",
                "Kibana",
                .product(name: "Logging", package: "swift-log"),
                "MetricsExtensions",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
            ],
            path: "Sources/EmceeLogging"
        ),
        .target(
            name: "EmceeLoggingTestHelpers",
            dependencies: [
                "EmceeLogging",
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Tests/EmceeLoggingTestHelpers"
        ),
        .testTarget(
            name: "EmceeLoggingTests",
            dependencies: [
                "EmceeLogging",
                "EmceeLoggingTestHelpers",
                "Kibana",
                .product(name: "Logging", package: "swift-log"),
                "QueueModels",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/EmceeLoggingTests"
        ),
        .target(
            name: "EmceeTypes",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
            ],
            path: "Sources/EmceeTypes"
        ),
        .target(
            name: "EmceeVersion",
            dependencies: [
                "QueueModels",
            ],
            path: "Sources/EmceeVersion"
        ),
        .target(
            name: "EventBus",
            dependencies: [
                .product(name: "CLTExtensions", package: "CommandLineToolkit"),
                "RunnerModels",
            ],
            path: "Sources/EventBus"
        ),
        .testTarget(
            name: "EventBusTests",
            dependencies: [
                "EventBus",
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
            ],
            path: "Tests/EventBusTests"
        ),
        .target(
            name: "Extensions",
            dependencies: [
            ],
            path: "Sources/Extensions"
        ),
        .testTarget(
            name: "ExtensionsTests",
            dependencies: [
                "Extensions",
            ],
            path: "Tests/ExtensionsTests"
        ),
        .target(
            name: "FileCache",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "Extensions",
                "FileLock",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/FileCache"
        ),
        .testTarget(
            name: "FileCacheTests",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "FileCache",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/FileCacheTests"
        ),
        .target(
            name: "FileLock",
            dependencies: [
            ],
            path: "Sources/FileLock"
        ),
        .testTarget(
            name: "FileLockTests",
            dependencies: [
                "FileLock",
            ],
            path: "Tests/FileLockTests"
        ),
        .target(
            name: "JunitReporting",
            dependencies: [
                "EmceeTypes",
            ],
            path: "Sources/JunitReporting"
        ),
        .testTarget(
            name: "JunitReportingTests",
            dependencies: [
                "EmceeTypes",
                "Extensions",
                "JunitReporting",
            ],
            path: "Tests/JunitReportingTests"
        ),
        .target(
            name: "Kibana",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "SocketModels", package: "CommandLineToolkit"),
            ],
            path: "Sources/Kibana"
        ),
        .testTarget(
            name: "KibanaTests",
            dependencies: [
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "EmceeLogging",
                "Kibana",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "URLSessionTestHelpers",
            ],
            path: "Tests/KibanaTests"
        ),
        .target(
            name: "ListeningSemaphore",
            dependencies: [
                .product(name: "CLTExtensions", package: "CommandLineToolkit"),
            ],
            path: "Sources/ListeningSemaphore"
        ),
        .testTarget(
            name: "ListeningSemaphoreTests",
            dependencies: [
                "ListeningSemaphore",
            ],
            path: "Tests/ListeningSemaphoreTests"
        ),
        .target(
            name: "LocalHostDeterminer",
            dependencies: [
                "EmceeLogging",
            ],
            path: "Sources/LocalHostDeterminer"
        ),
        .target(
            name: "LocalQueueServerRunner",
            dependencies: [
                "AutomaticTermination",
                "Deployer",
                "DistDeployer",
                "DistWorkerModels",
                "EmceeLogging",
                "FileLock",
                "LocalHostDeterminer",
                "LoggingSetup",
                "MetricsExtensions",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueCommunication",
                "QueueModels",
                "QueueServer",
                "QueueServerPortProvider",
                "RemotePortDeterminer",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/LocalQueueServerRunner"
        ),
        .testTarget(
            name: "LocalQueueServerRunnerTests",
            dependencies: [
                "AutomaticTermination",
                "AutomaticTerminationTestHelpers",
                "Deployer",
                "DistDeployer",
                "LocalQueueServerRunner",
                "LoggingSetup",
                "MetricsExtensions",
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueServer",
                "QueueServerPortProviderTestHelpers",
                "QueueServerTestHelpers",
                "RemotePortDeterminer",
                "RemotePortDeterminerTestHelpers",
                "ScheduleStrategy",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Tests/LocalQueueServerRunnerTests"
        ),
        .target(
            name: "LoggingSetup",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "Kibana",
                "LocalHostDeterminer",
                .product(name: "Logging", package: "swift-log"),
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
            ],
            path: "Sources/LoggingSetup"
        ),
        .testTarget(
            name: "LoggingTests",
            dependencies: [
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "EmceeLogging",
                "EmceeLoggingTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
            ],
            path: "Tests/LoggingTests"
        ),
        .target(
            name: "MetricsExtensions",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
                .product(name: "Metrics", package: "CommandLineToolkit"),
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Statsd", package: "CommandLineToolkit"),
            ],
            path: "Sources/MetricsExtensions"
        ),
        .testTarget(
            name: "MetricsExtensionsTests",
            dependencies: [
                .product(name: "Graphite", package: "CommandLineToolkit"),
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/MetricsExtensionsTests"
        ),
        .target(
            name: "ObservableFileReader",
            dependencies: [
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
            ],
            path: "Sources/ObservableFileReader"
        ),
        .testTarget(
            name: "ObservableFileReaderTests",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "ObservableFileReader",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
            ],
            path: "Tests/ObservableFileReaderTests"
        ),
        .target(
            name: "Plugin",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeLogging",
                "EventBus",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "JSONStream", package: "CommandLineToolkit"),
                "LoggingSetup",
                "PluginSupport",
                .product(name: "Starscream", package: "Starscream"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
            ],
            path: "Sources/Plugin"
        ),
        .target(
            name: "PluginManager",
            dependencies: [
                "EmceeLogging",
                "EventBus",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "LocalHostDeterminer",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginSupport",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "ResourceLocationResolver",
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
            ],
            path: "Sources/PluginManager"
        ),
        .target(
            name: "PluginManagerTestHelpers",
            dependencies: [
                "EventBus",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "PluginManager",
                "PluginSupport",
            ],
            path: "Tests/PluginManagerTestHelpers"
        ),
        .testTarget(
            name: "PluginManagerTests",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EventBus",
                "Extensions",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginManager",
                "PluginSupport",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "ResourceLocation",
                "ResourceLocationResolverTestHelpers",
                "RunnerTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
            ],
            path: "Tests/PluginManagerTests"
        ),
        .target(
            name: "PluginSupport",
            dependencies: [
                "TypedResourceLocation",
            ],
            path: "Sources/PluginSupport"
        ),
        .target(
            name: "PortDeterminer",
            dependencies: [
                "EmceeLogging",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
            ],
            path: "Sources/PortDeterminer"
        ),
        .testTarget(
            name: "PortDeterminerTests",
            dependencies: [
                "PortDeterminer",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
            ],
            path: "Tests/PortDeterminerTests"
        ),
        .target(
            name: "QueueClient",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "DistWorkerModels",
                "EmceeLogging",
                "QueueModels",
                "RESTMethods",
                "RequestSender",
                "ScheduleStrategy",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerAlivenessModels",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/QueueClient"
        ),
        .testTarget(
            name: "QueueClientTests",
            dependencies: [
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
                "MetricsExtensions",
                "QueueClient",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RESTMethods",
                "RequestSender",
                "RequestSenderTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerAlivenessModels",
            ],
            path: "Tests/QueueClientTests"
        ),
        .target(
            name: "QueueCommunication",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeLogging",
                .product(name: "Graphite", package: "CommandLineToolkit"),
                "LocalHostDeterminer",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                "QueueCommunicationModels",
                "QueueModels",
                "QueueServerPortProvider",
                "RESTMethods",
                "RemotePortDeterminer",
                "RequestSender",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Timer", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Sources/QueueCommunication"
        ),
        .target(
            name: "QueueCommunicationModels",
            dependencies: [
            ],
            path: "Sources/QueueCommunicationModels"
        ),
        .target(
            name: "QueueCommunicationTestHelpers",
            dependencies: [
                "DeployerTestHelpers",
                "QueueCommunication",
                "QueueCommunicationModels",
                "QueueModels",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Tests/QueueCommunicationTestHelpers"
        ),
        .testTarget(
            name: "QueueCommunicationTests",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueServerPortProviderTestHelpers",
                "RESTMethods",
                "RemotePortDeterminer",
                "RemotePortDeterminerTestHelpers",
                "RequestSenderTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/QueueCommunicationTests"
        ),
        .target(
            name: "QueueModels",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirModels",
                "MetricsExtensions",
                "PluginSupport",
                "RunnerModels",
                "SimulatorPoolModels",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/QueueModels"
        ),
        .target(
            name: "QueueModelsTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "DeveloperDirModels",
                "MetricsExtensions",
                "PluginSupport",
                "QueueModels",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/QueueModelsTestHelpers"
        ),
        .testTarget(
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
            name: "QueueServer",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "AutomaticTermination",
                "BalancingBucketQueue",
                "BucketQueue",
                "BucketQueueModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "Deployer",
                "DistWorkerModels",
                "EmceeLogging",
                "EventBus",
                .product(name: "Graphite", package: "CommandLineToolkit"),
                "LocalHostDeterminer",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                "PortDeterminer",
                "QueueCommunication",
                "QueueModels",
                "QueueServerPortProvider",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "RequestSender",
                "RunnerModels",
                "ScheduleStrategy",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TestHistoryStorage",
                "TestHistoryTracker",
                .product(name: "Timer", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "WorkerAlivenessModels",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/QueueServer"
        ),
        .target(
            name: "QueueServerPortProvider",
            dependencies: [
                .product(name: "SocketModels", package: "CommandLineToolkit"),
            ],
            path: "Sources/QueueServerPortProvider"
        ),
        .target(
            name: "QueueServerPortProviderTestHelpers",
            dependencies: [
                "QueueServerPortProvider",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
            ],
            path: "Tests/QueueServerPortProviderTestHelpers"
        ),
        .target(
            name: "QueueServerTestHelpers",
            dependencies: [
                "QueueModels",
                "QueueServer",
                "ScheduleStrategy",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
            ],
            path: "Tests/QueueServerTestHelpers"
        ),
        .testTarget(
            name: "QueueServerTests",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "AutomaticTermination",
                "AutomaticTerminationTestHelpers",
                "BalancingBucketQueue",
                "BucketQueue",
                "BucketQueueModels",
                "BucketQueueTestHelpers",
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
                "EmceeLogging",
                .product(name: "Graphite", package: "CommandLineToolkit"),
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                "PortDeterminer",
                "QueueClient",
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "QueueServer",
                "QueueServerPortProvider",
                "QueueServerPortProviderTestHelpers",
                "QueueServerTestHelpers",
                "RESTMethods",
                "RemotePortDeterminerTestHelpers",
                "RequestSender",
                "RequestSenderTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "ScheduleStrategy",
                "SimulatorPoolTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "UniqueIdentifierGeneratorTestHelpers",
                "WorkerAlivenessModels",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/QueueServerTests"
        ),
        .target(
            name: "RESTInterfaces",
            dependencies: [
                "QueueModels",
            ],
            path: "Sources/RESTInterfaces"
        ),
        .target(
            name: "RESTMethods",
            dependencies: [
                "Deployer",
                "DistWorkerModels",
                "QueueModels",
                "RESTInterfaces",
                "RequestSender",
                "ScheduleStrategy",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                "WorkerAlivenessModels",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/RESTMethods"
        ),
        .target(
            name: "RESTServer",
            dependencies: [
                "AutomaticTermination",
                "EmceeLogging",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
            ],
            path: "Sources/RESTServer"
        ),
        .testTarget(
            name: "RESTServerTests",
            dependencies: [
                "AutomaticTerminationTestHelpers",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Tests/RESTServerTests"
        ),
        .target(
            name: "RemotePortDeterminer",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "EmceeLogging",
                "QueueClient",
                "QueueModels",
                "RequestSender",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Sources/RemotePortDeterminer"
        ),
        .target(
            name: "RemotePortDeterminerTestHelpers",
            dependencies: [
                "QueueModels",
                "RemotePortDeterminer",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
            ],
            path: "Tests/RemotePortDeterminerTestHelpers"
        ),
        .testTarget(
            name: "RemotePortDeterminerTests",
            dependencies: [
                "PortDeterminer",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RemotePortDeterminer",
                "RequestSender",
                "RequestSenderTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/RemotePortDeterminerTests"
        ),
        .target(
            name: "RequestSender",
            dependencies: [
                "EmceeLogging",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Sources/RequestSender"
        ),
        .target(
            name: "RequestSenderTestHelpers",
            dependencies: [
                "RequestSender",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Tests/RequestSenderTestHelpers"
        ),
        .testTarget(
            name: "RequestSenderTests",
            dependencies: [
                "RequestSender",
                "RequestSenderTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Tests/RequestSenderTests"
        ),
        .target(
            name: "ResourceLocation",
            dependencies: [
                .product(name: "PathLib", package: "CommandLineToolkit"),
            ],
            path: "Sources/ResourceLocation"
        ),
        .target(
            name: "ResourceLocationResolver",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "EmceeLogging",
                "FileCache",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "ResourceLocation",
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TypedResourceLocation",
                "URLResource",
            ],
            path: "Sources/ResourceLocationResolver"
        ),
        .target(
            name: "ResourceLocationResolverTestHelpers",
            dependencies: [
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "ResourceLocation",
                "ResourceLocationResolver",
            ],
            path: "Tests/ResourceLocationResolverTestHelpers"
        ),
        .testTarget(
            name: "ResourceLocationResolverTests",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeLogging",
                "FileCache",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "ResourceLocation",
                "ResourceLocationResolver",
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "URLResource",
                "URLSessionTestHelpers",
            ],
            path: "Tests/ResourceLocationResolverTests"
        ),
        .testTarget(
            name: "ResourceLocationTests",
            dependencies: [
                "ResourceLocation",
                .product(name: "Tmp", package: "CommandLineToolkit"),
            ],
            path: "Tests/ResourceLocationTests"
        ),
        .target(
            name: "ResultStream",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeLogging",
                "EmceeTypes",
                .product(name: "JSONStream", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "ResultStreamModels",
                "Runner",
                "RunnerModels",
            ],
            path: "Sources/ResultStream"
        ),
        .target(
            name: "ResultStreamModels",
            dependencies: [
                "RunnerModels",
            ],
            path: "Sources/ResultStreamModels"
        ),
        .target(
            name: "ResultStreamModelsTestHelpers",
            dependencies: [
                "RunnerModels",
            ],
            path: "Tests/ResultStreamModelsTestHelpers"
        ),
        .testTarget(
            name: "ResultStreamModelsTests",
            dependencies: [
                "ResultStreamModels",
                "ResultStreamModelsTestHelpers",
                "RunnerModels",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/ResultStreamModelsTests"
        ),
        .testTarget(
            name: "ResultStreamTests",
            dependencies: [
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "ResultStream",
                "ResultStreamModels",
                "RunnerModels",
                "RunnerTestHelpers",
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/ResultStreamTests"
        ),
        .target(
            name: "Runner",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "BuildArtifacts",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeLogging",
                "EmceeTypes",
                "EventBus",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
                "LocalHostDeterminer",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginManager",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                "RunnerModels",
                "SimulatorPoolModels",
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TestsWorkingDirectorySupport",
                .product(name: "Timer", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/Runner"
        ),
        .target(
            name: "RunnerModels",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirModels",
                "EmceeTypes",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginSupport",
                "SimulatorPoolModels",
            ],
            path: "Sources/RunnerModels"
        ),
        .target(
            name: "RunnerTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeLogging",
                "EmceeTypes",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "Runner",
                "RunnerModels",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
            ],
            path: "Tests/RunnerTestHelpers"
        ),
        .testTarget(
            name: "RunnerTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DeveloperDirLocatorTestHelpers",
                "EmceeLogging",
                "EventBus",
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                "PluginManagerTestHelpers",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueModels",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/RunnerTests"
        ),
        .target(
            name: "SSHDeployer",
            dependencies: [
                "Deployer",
                "EmceeLogging",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "Shout", package: "Shout"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/SSHDeployer"
        ),
        .testTarget(
            name: "SSHDeployerTests",
            dependencies: [
                "Deployer",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "SSHDeployer",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/SSHDeployerTests"
        ),
        .target(
            name: "ScheduleStrategy",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirModels",
                "EmceeLogging",
                "PluginSupport",
                "QueueModels",
                "RunnerModels",
                "SimulatorPoolModels",
                .product(name: "Types", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/ScheduleStrategy"
        ),
        .testTarget(
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
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/ScheduleStrategyTests"
        ),
        .target(
            name: "Scheduler",
            dependencies: [
                "BuildArtifacts",
                "DI",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "ListeningSemaphore",
                "LocalHostDeterminer",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                "PluginManager",
                "PluginSupport",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "ScheduleStrategy",
                "SimulatorPool",
                "SimulatorPoolModels",
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/Scheduler"
        ),
        .target(
            name: "SimulatorPool",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "AutomaticTermination",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
                "LocalHostDeterminer",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "PlistLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                "ResourceLocationResolver",
                "RunnerModels",
                "SimulatorPoolModels",
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/SimulatorPool"
        ),
        .target(
            name: "SimulatorPoolModels",
            dependencies: [
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "ResourceLocation",
                "TypedResourceLocation",
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Sources/SimulatorPoolModels"
        ),
        .testTarget(
            name: "SimulatorPoolModelsTests",
            dependencies: [
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/SimulatorPoolModelsTests"
        ),
        .target(
            name: "SimulatorPoolTestHelpers",
            dependencies: [
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                .product(name: "Tmp", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Tests/SimulatorPoolTestHelpers"
        ),
        .testTarget(
            name: "SimulatorPoolTests",
            dependencies: [
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "PlistLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueModels",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/SimulatorPoolTests"
        ),
        .target(
            name: "SimulatorVideoRecorder",
            dependencies: [
                "EmceeLogging",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "SimulatorPoolModels",
            ],
            path: "Sources/SimulatorVideoRecorder"
        ),
        .testTarget(
            name: "SocketModelsTests",
            dependencies: [
                .product(name: "SocketModels", package: "CommandLineToolkit"),
            ],
            path: "Tests/SocketModelsTests"
        ),
        .target(
            name: "TestArgFile",
            dependencies: [
                "BuildArtifacts",
                "DeveloperDirModels",
                "LoggingSetup",
                "MetricsExtensions",
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
            name: "TestArgFileTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "LoggingSetup",
                "MetricsExtensions",
                "PluginSupport",
                "QueueModels",
                "ResourceLocation",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                "TestArgFile",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/TestArgFileTests"
        ),
        .target(
            name: "TestDiscovery",
            dependencies: [
                "AppleTools",
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "BuildArtifacts",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
                "LocalHostDeterminer",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginManager",
                "PluginSupport",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                "RequestSender",
                "ResourceLocationResolver",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TestArgFile",
                .product(name: "Tmp", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/TestDiscovery"
        ),
        .testTarget(
            name: "TestDiscoveryTests",
            dependencies: [
                "AppleTools",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                "EmceeLogging",
                "FileCache",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginManagerTestHelpers",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueModels",
                "RequestSender",
                "RequestSenderTestHelpers",
                "ResourceLocation",
                "ResourceLocationResolver",
                "ResourceLocationResolverTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TestArgFile",
                "TestDiscovery",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "URLResource",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/TestDiscoveryTests"
        ),
        .target(
            name: "TestHistoryModels",
            dependencies: [
                "BuildArtifacts",
                "QueueModels",
                "RunnerModels",
            ],
            path: "Sources/TestHistoryModels"
        ),
        .target(
            name: "TestHistoryStorage",
            dependencies: [
                "QueueModels",
                "RunnerModels",
                "TestHistoryModels",
            ],
            path: "Sources/TestHistoryStorage"
        ),
        .target(
            name: "TestHistoryTestHelpers",
            dependencies: [
                "BucketQueue",
                "BucketQueueModels",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RunnerModels",
                "RunnerTestHelpers",
                "TestHistoryModels",
                "TestHistoryStorage",
                "TestHistoryTracker",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/TestHistoryTestHelpers"
        ),
        .target(
            name: "TestHistoryTracker",
            dependencies: [
                "BucketQueueModels",
                "QueueModels",
                "RunnerModels",
                "TestHistoryModels",
                "TestHistoryStorage",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/TestHistoryTracker"
        ),
        .testTarget(
            name: "TestHistoryTrackerTests",
            dependencies: [
                "BucketQueue",
                "BucketQueueModels",
                "BucketQueueTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RunnerTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "TestHistoryModels",
                "TestHistoryTestHelpers",
                "TestHistoryTracker",
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/TestHistoryTrackerTests"
        ),
        .target(
            name: "TestingPlugin",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EventBus",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "Plugin",
            ],
            path: "Sources/TestingPlugin"
        ),
        .target(
            name: "TestsWorkingDirectorySupport",
            dependencies: [
            ],
            path: "Sources/TestsWorkingDirectorySupport"
        ),
        .target(
            name: "TypedResourceLocation",
            dependencies: [
                "ResourceLocation",
            ],
            path: "Sources/TypedResourceLocation"
        ),
        .target(
            name: "URLResource",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "EmceeLogging",
                "FileCache",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Sources/URLResource"
        ),
        .testTarget(
            name: "URLResourceTests",
            dependencies: [
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "FileCache",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "URLResource",
            ],
            path: "Tests/URLResourceTests"
        ),
        .target(
            name: "URLSessionTestHelpers",
            dependencies: [
            ],
            path: "Tests/URLSessionTestHelpers"
        ),
        .target(
            name: "UniqueIdentifierGenerator",
            dependencies: [
            ],
            path: "Sources/UniqueIdentifierGenerator"
        ),
        .target(
            name: "UniqueIdentifierGeneratorTestHelpers",
            dependencies: [
                "UniqueIdentifierGenerator",
            ],
            path: "Tests/UniqueIdentifierGeneratorTestHelpers"
        ),
        .target(
            name: "WorkerAlivenessModels",
            dependencies: [
                "QueueCommunicationModels",
                "QueueModels",
            ],
            path: "Sources/WorkerAlivenessModels"
        ),
        .target(
            name: "WorkerAlivenessProvider",
            dependencies: [
                "EmceeLogging",
                "Extensions",
                "QueueCommunication",
                "QueueCommunicationModels",
                "QueueModels",
                "WorkerAlivenessModels",
            ],
            path: "Sources/WorkerAlivenessProvider"
        ),
        .testTarget(
            name: "WorkerAlivenessProviderTests",
            dependencies: [
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "WorkerAlivenessModels",
                "WorkerAlivenessProvider",
            ],
            path: "Tests/WorkerAlivenessProviderTests"
        ),
        .target(
            name: "WorkerCapabilities",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "PlistLib", package: "CommandLineToolkit"),
                "QueueModels",
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/WorkerCapabilities"
        ),
        .target(
            name: "WorkerCapabilitiesModels",
            dependencies: [
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Sources/WorkerCapabilitiesModels"
        ),
        .testTarget(
            name: "WorkerCapabilitiesTests",
            dependencies: [
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PlistLib", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/WorkerCapabilitiesTests"
        ),
        .target(
            name: "XcodebuildTestRunnerConstants",
            dependencies: [
            ],
            path: "Sources/XcodebuildTestRunnerConstants"
        ),
    ]
)
