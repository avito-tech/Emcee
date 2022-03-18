// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "EmceeTestRunner",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .executable(name: "Emcee", targets: ["EmceeBinary"]),
        .executable(name: "testing_plugin", targets: ["TestingPlugin"]),
        .library(name: "EmceePlugin", targets: ["EmceeLogging", "Plugin"]),
        .library(name: "EmceeCommunications", targets: ["PortDeterminer", "QueueClient", "QueueCommunication", "RemotePortDeterminer", "RequestSender"]),
        .library(name: "EmceeInterfaces", targets: ["BuildArtifacts", "DeveloperDirModels", "EmceeVersion", "PluginSupport", "QueueModels", "ResourceLocation", "ResourceLocationResolver", "RunnerModels", "SimulatorPoolModels", "SimulatorVideoRecorder", "TestArgFile", "TestDiscovery", "TestsWorkingDirectorySupport", "TypedResourceLocation", "WorkerAlivenessModels", "WorkerCapabilitiesModels", "XcodebuildTestRunnerConstants"]),
        .library(name: "EmceeGuts", targets: ["AppleTools", "ArgLib", "AutomaticTermination", "BalancingBucketQueue", "BucketQueue", "BucketQueueModels", "BuildArtifacts", "ChromeTracing", "Deployer", "DeveloperDirLocator", "DeveloperDirModels", "DistDeployer", "DistWorker", "DistWorkerModels", "EmceeDI", "EmceeExtensions", "EmceeLib", "EmceeLogging", "EmceeTypes", "EmceeVersion", "EventBus", "FileCache", "FileLock", "JunitReporting", "Kibana", "ListeningSemaphore", "LocalHostDeterminer", "LocalQueueServerRunner", "MetricsExtensions", "ObservableFileReader", "Plugin", "PluginManager", "PluginSupport", "PortDeterminer", "QueueClient", "QueueCommunication", "QueueCommunicationModels", "QueueModels", "QueueServer", "QueueServerPortProvider", "RemotePortDeterminer", "RequestSender", "ResourceLocation", "ResourceLocationResolver", "RESTInterfaces", "RESTMethods", "RESTServer", "ResultStream", "ResultStreamModels", "Runner", "RunnerModels", "Scheduler", "ScheduleStrategy", "SimulatorPool", "SimulatorPoolModels", "SimulatorVideoRecorder", "SSHDeployer", "TestArgFile", "TestDiscovery", "TestHistoryModels", "TestHistoryStorage", "TestHistoryTracker", "TestsWorkingDirectorySupport", "TypedResourceLocation", "UniqueIdentifierGenerator", "URLResource", "WorkerAlivenessModels", "WorkerAlivenessProvider", "WorkerCapabilities", "WorkerCapabilitiesModels", "XcodebuildTestRunnerConstants"]),
    ],
    dependencies: [
        .package(name: "CommandLineToolkit", url: "https://github.com/avito-tech/CommandLineToolkit.git", .exact("1.0.10")),
        .package(name: "CountedSet", url: "https://github.com/0x7fs/CountedSet", .branch("master")),
        .package(name: "OrderedSet", url: "https://github.com/Weebly/OrderedSet", .exact("5.0.0")),
        .package(name: "Shout", url: "https://github.com/jakeheis/Shout.git", .exact("0.5.4")),
        .package(name: "Socket", url: "https://github.com/IBM-Swift/BlueSocket", .exact("1.0.46")),
        .package(name: "Starscream", url: "https://github.com/daltoniam/Starscream.git", .exact("3.0.6")),
        .package(name: "Swifter", url: "https://github.com/httpswift/swifter.git", .exact("1.5.0")),
    ],
    targets: [
        .target(
            name: "AndroidEmulatorModels",
            dependencies: [
                "TestDestination",
            ],
            path: "Sources/AndroidEmulatorModels"
        ),
        .target(
            name: "AndroidTestModels",
            dependencies: [
                "AndroidEmulatorModels",
                "BuildArtifacts",
                "CommonTestModels",
                "TestDestination",
            ],
            path: "Sources/AndroidTestModels"
        ),
        .target(
            name: "AndroidTestModelsTestHelpers",
            dependencies: [
                "AndroidTestModels",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
            ],
            path: "Tests/AndroidTestModelsTestHelpers"
        ),
        .target(
            name: "AppleTestModels",
            dependencies: [
                "BuildArtifacts",
                "CommonTestModels",
                "DeveloperDirModels",
                "PluginSupport",
                "SimulatorPoolModels",
                "TestDestination",
            ],
            path: "Sources/AppleTestModels"
        ),
        .target(
            name: "AppleTestModelsTestHelpers",
            dependencies: [
                "AppleTestModels",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                "DeveloperDirModels",
                "PluginSupport",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
            ],
            path: "Tests/AppleTestModelsTestHelpers"
        ),
        .target(
            name: "AppleTools",
            dependencies: [
                "AppleTestModels",
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "BuildArtifacts",
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "MetricsExtensions",
                "ObservableFileReader",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "PlistLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                "ResourceLocation",
                "ResourceLocationResolver",
                "ResultStream",
                "ResultStreamModels",
                "Runner",
                "RunnerModels",
                "SimulatorPool",
                "SimulatorPoolModels",
                .product(name: "Statsd", package: "CommandLineToolkit"),
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
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Tests/AppleToolsTestHelpers"
        ),
        .testTarget(
            name: "AppleToolsTests",
            dependencies: [
                "AppleTools",
                "AppleToolsTestHelpers",
                "BuildArtifacts",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                "EmceeTypes",
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueModels",
                "ResourceLocationResolverTestHelpers",
                "ResultStreamModels",
                "ResultStreamModelsTestHelpers",
                "Runner",
                "RunnerModels",
                "RunnerTestHelpers",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
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
                "CommonTestModels",
                .product(name: "CountedSet", package: "CountedSet"),
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeExtensions",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                "QueueModels",
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
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "SimulatorPoolTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "TestHistoryStorage",
                "TestHistoryTracker",
                "UniqueIdentifierGenerator",
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
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeExtensions",
                "EmceeLogging",
                "QueueModels",
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
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "EmceeLogging",
                "QueueModels",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "TestHistoryTestHelpers",
                "TestHistoryTracker",
                .product(name: "Types", package: "CommandLineToolkit"),
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
                "AppleTestModelsTestHelpers",
                "BucketQueue",
                "BucketQueueModels",
                "BucketQueueTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DistWorkerModels",
                "QueueCommunication",
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "SimulatorPoolTestHelpers",
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
                "TestDiscovery",
            ],
            path: "Tests/BuildArtifactsTestHelpers"
        ),
        .target(
            name: "ChromeTracing",
            dependencies: [
            ],
            path: "Sources/ChromeTracing"
        ),
        .testTarget(
            name: "ChromeTracingTests",
            dependencies: [
                "ChromeTracing",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/ChromeTracingTests"
        ),
        .target(
            name: "CommonTestModels",
            dependencies: [
                "EmceeTypes",
                "TestDestination",
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Sources/CommonTestModels"
        ),
        .target(
            name: "CommonTestModelsTestHelpers",
            dependencies: [
                "CommonTestModels",
                "EmceeTypes",
                "QueueModels",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TestDestination",
            ],
            path: "Tests/CommonTestModelsTestHelpers"
        ),
        .testTarget(
            name: "CommonTestModelsTests",
            dependencies: [
                "CommonTestModels",
            ],
            path: "Tests/CommonTestModelsTests"
        ),
        .target(
            name: "Deployer",
            dependencies: [
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "QueueModels",
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "Zip",
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
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGeneratorTestHelpers",
                "ZipTestHelpers",
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
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "LaunchdUtils", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "QueueModels",
                "QueueServerConfiguration",
                "SSHDeployer",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "TypedResourceLocation",
                "UniqueIdentifierGenerator",
                "Zip",
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
                "AutomaticTermination",
                .product(name: "CountedSet", package: "CountedSet"),
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DistWorkerModels",
                "EmceeDI",
                "EmceeExtensions",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "MetricsExtensions",
                "QueueClient",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "RequestSender",
                "ResourceLocationResolver",
                "Scheduler",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerCapabilities",
            ],
            path: "Sources/DistWorker"
        ),
        .target(
            name: "DistWorkerModels",
            dependencies: [
                .product(name: "CLTExtensions", package: "CommandLineToolkit"),
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
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                "DistWorker",
                "MetricsExtensions",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RequestSender",
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
            name: "EmceeDI",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
            ],
            path: "Sources/EmceeDI"
        ),
        .testTarget(
            name: "EmceeDITests",
            dependencies: [
                "EmceeDI",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/EmceeDITests"
        ),
        .target(
            name: "EmceeExtensions",
            dependencies: [
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PlistLib", package: "CommandLineToolkit"),
            ],
            path: "Sources/EmceeExtensions"
        ),
        .testTarget(
            name: "EmceeExtensionsTests",
            dependencies: [
                "EmceeExtensions",
                .product(name: "PlistLib", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/EmceeExtensionsTests"
        ),
        .target(
            name: "EmceeLib",
            dependencies: [
                "AppleTestModels",
                "AppleTools",
                "ArgLib",
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "AutomaticTermination",
                "BuildArtifacts",
                "ChromeTracing",
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "Deployer",
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "DistDeployer",
                "DistWorker",
                "DistWorkerModels",
                "EmceeDI",
                "EmceeExtensions",
                "EmceeLogging",
                "EmceeLoggingModels",
                "EmceeVersion",
                "EventBus",
                "FileCache",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "HostnameProvider",
                "JunitReporting",
                "LocalHostDeterminer",
                "LocalQueueServerRunner",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginManager",
                "PluginSupport",
                "PortDeterminer",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueClient",
                "QueueCommunication",
                "QueueModels",
                "QueueServer",
                "QueueServerConfiguration",
                "QueueServerPortProvider",
                "RESTMethods",
                "RESTServer",
                "RemotePortDeterminer",
                "RequestSender",
                "ResourceLocation",
                "ResourceLocationResolver",
                "Runner",
                "ScheduleStrategy",
                .product(name: "SignalHandling", package: "CommandLineToolkit"),
                "SimulatorPool",
                "SimulatorPoolModels",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TestArgFile",
                "TestDestination",
                "TestDiscovery",
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "TypedResourceLocation",
                .product(name: "Types", package: "CommandLineToolkit"),
                "URLResource",
                "UniqueIdentifierGenerator",
                "WhatIsMyAddress",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
                "Zip",
            ],
            path: "Sources/EmceeLib"
        ),
        .testTarget(
            name: "EmceeLibTests",
            dependencies: [
                "AppleTestModels",
                "AppleTestModelsTestHelpers",
                "AppleTools",
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "EmceeLib",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "MetricsTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueModels",
                "QueueModelsTestHelpers",
                "ResourceLocationResolverTestHelpers",
                "ScheduleStrategy",
                "SimulatorPool",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                "TestArgFile",
                "TestDestination",
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
                "EmceeExtensions",
                "EmceeLoggingModels",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "Kibana",
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                .product(name: "Tmp", package: "CommandLineToolkit"),
            ],
            path: "Sources/EmceeLogging"
        ),
        .target(
            name: "EmceeLoggingModels",
            dependencies: [
            ],
            path: "Sources/EmceeLoggingModels"
        ),
        .target(
            name: "EmceeLoggingTestHelpers",
            dependencies: [
                "EmceeLogging",
                "EmceeLoggingModels",
            ],
            path: "Tests/EmceeLoggingTestHelpers"
        ),
        .testTarget(
            name: "EmceeLoggingTests",
            dependencies: [
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "EmceeLogging",
                "EmceeLoggingModels",
                "EmceeLoggingTestHelpers",
                "Kibana",
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
                "CommonTestModels",
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
            name: "FileCache",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeExtensions",
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
                "EmceeExtensions",
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
            name: "HostnameProvider",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
            ],
            path: "Sources/HostnameProvider"
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
                "EmceeExtensions",
                "EmceeTypes",
                "JunitReporting",
            ],
            path: "Tests/JunitReportingTests"
        ),
        .target(
            name: "Kibana",
            dependencies: [
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeExtensions",
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
            ],
            path: "Sources/LocalHostDeterminer"
        ),
        .target(
            name: "LocalQueueServerRunner",
            dependencies: [
                "AutomaticTermination",
                "Deployer",
                "DistDeployer",
                "EmceeLogging",
                "FileLock",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "QueueCommunication",
                "QueueModels",
                "QueueServer",
                "QueueServerPortProvider",
                "RemotePortDeterminer",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "Zip",
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
                "MetricsExtensions",
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueCommunicationTestHelpers",
                "QueueModels",
                "QueueServer",
                "QueueServerConfiguration",
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
            name: "LogStreaming",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                .product(name: "CLTExtensions", package: "CommandLineToolkit"),
                "EmceeLogging",
                "EmceeLoggingModels",
                "LogStreamingModels",
                "QueueClient",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "RequestSender",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Sources/LogStreaming"
        ),
        .target(
            name: "LogStreamingModels",
            dependencies: [
                "EmceeLoggingModels",
                "QueueModels",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
            ],
            path: "Sources/LogStreamingModels"
        ),
        .target(
            name: "LogStreamingTestHelpers",
            dependencies: [
                "EmceeLogging",
                "EmceeLoggingModels",
                "EmceeLoggingTestHelpers",
                "LogStreaming",
                "QueueModels",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
            ],
            path: "Tests/LogStreamingTestHelpers"
        ),
        .testTarget(
            name: "LogStreamingTests",
            dependencies: [
                "EmceeLogging",
                "EmceeLoggingModels",
                "EmceeLoggingTestHelpers",
                "LogStreaming",
                "LogStreamingModels",
                "LogStreamingTestHelpers",
                "QueueModels",
                "RequestSender",
                "RequestSenderTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/LogStreamingTests"
        ),
        .testTarget(
            name: "LoggingTests",
            dependencies: [
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "EmceeLogging",
                "EmceeLoggingModels",
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
                "EmceeExtensions",
                "EmceeLogging",
                "EmceeLoggingModels",
                "EventBus",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "JSONStream", package: "CommandLineToolkit"),
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
                "HostnameProvider",
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
                "CommonTestModelsTestHelpers",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeExtensions",
                "EventBus",
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
                .product(name: "Socket", package: "Socket"),
                .product(name: "SocketModels", package: "CommandLineToolkit"),
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
                "CommonTestModelsTestHelpers",
                "DistWorkerModels",
                "DistWorkerModelsTestHelpers",
                "MetricsExtensions",
                "QueueClient",
                "QueueModels",
                "QueueModelsTestHelpers",
                "RESTMethods",
                "RequestSender",
                "RequestSenderTestHelpers",
                "ScheduleStrategy",
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
                "AndroidTestModels",
                "AppleTestModels",
                "CommonTestModels",
                "MetricsExtensions",
                "PluginSupport",
                "SimulatorPoolModels",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                "TestDestination",
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/QueueModels"
        ),
        .target(
            name: "QueueModelsTestHelpers",
            dependencies: [
                "AndroidTestModels",
                "AndroidTestModelsTestHelpers",
                "AppleTestModels",
                "AppleTestModelsTestHelpers",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                "MetricsExtensions",
                "QueueModels",
                "SimulatorPoolTestHelpers",
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerCapabilitiesModels",
            ],
            path: "Tests/QueueModelsTestHelpers"
        ),
        .testTarget(
            name: "QueueModelsTests",
            dependencies: [
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                "QueueModels",
                "SimulatorPoolTestHelpers",
                "TestDestination",
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
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "Deployer",
                "DistWorkerModels",
                "EmceeLogging",
                "EventBus",
                .product(name: "Graphite", package: "CommandLineToolkit"),
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
                "ScheduleStrategy",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Statsd", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TestHistoryStorage",
                "TestHistoryTracker",
                .product(name: "Timer", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "WhatIsMyAddress",
                "WorkerAlivenessModels",
                "WorkerAlivenessProvider",
                "WorkerCapabilities",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/QueueServer"
        ),
        .target(
            name: "QueueServerConfiguration",
            dependencies: [
                "AutomaticTermination",
                "Deployer",
                "DistWorkerModels",
                "EmceeExtensions",
                "MetricsExtensions",
                "QueueModels",
            ],
            path: "Sources/QueueServerConfiguration"
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
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
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
                "RequestSender",
                "RequestSenderTestHelpers",
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
                .product(name: "PathLib", package: "CommandLineToolkit"),
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
                "EmceeExtensions",
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
                "EmceeExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
            ],
            path: "Sources/ResourceLocation"
        ),
        .target(
            name: "ResourceLocationResolver",
            dependencies: [
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
                "EmceeExtensions",
                "EmceeLogging",
                "FileCache",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
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
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "EmceeLogging",
                "EmceeTypes",
                .product(name: "JSONStream", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "ResultStreamModels",
                "Runner",
            ],
            path: "Sources/ResultStream"
        ),
        .target(
            name: "ResultStreamModels",
            dependencies: [
            ],
            path: "Sources/ResultStreamModels"
        ),
        .target(
            name: "ResultStreamModelsTestHelpers",
            dependencies: [
                "CommonTestModels",
            ],
            path: "Tests/ResultStreamModelsTestHelpers"
        ),
        .testTarget(
            name: "ResultStreamModelsTests",
            dependencies: [
                "CommonTestModels",
                "ResultStreamModels",
                "ResultStreamModelsTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/ResultStreamModelsTests"
        ),
        .testTarget(
            name: "ResultStreamTests",
            dependencies: [
                "CommonTestModels",
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "ResultStream",
                "ResultStreamModels",
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
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeLogging",
                "EmceeLoggingModels",
                "EmceeTypes",
                "EventBus",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
                "HostnameProvider",
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
                "AppleTestModels",
                "CommonTestModels",
                "DeveloperDirModels",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "SimulatorPoolModels",
            ],
            path: "Sources/RunnerModels"
        ),
        .target(
            name: "RunnerTestHelpers",
            dependencies: [
                "BuildArtifacts",
                "CommonTestModels",
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeLogging",
                "EmceeLoggingModels",
                "EmceeTypes",
                "MetricsExtensions",
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
                "AppleTestModelsTestHelpers",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
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
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "Shout", package: "Shout"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "Zip",
            ],
            path: "Sources/SSHDeployer"
        ),
        .testTarget(
            name: "SSHDeployerTests",
            dependencies: [
                "Deployer",
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "SSHDeployer",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGeneratorTestHelpers",
                "ZipTestHelpers",
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
                "AppleTestModelsTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
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
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "DistWorkerModels",
                "EmceeDI",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                "ListeningSemaphore",
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
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeExtensions",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
                .product(name: "Metrics", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "PlistLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                "QueueModels",
                "ResourceLocationResolver",
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
                "CommonTestModels",
                "DeveloperDirModels",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "TestDestination",
                "TypedResourceLocation",
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
                "CommonTestModels",
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                "DeveloperDirModels",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "SimulatorPool",
                "SimulatorPoolModels",
                "TestDestination",
                .product(name: "Tmp", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
            ],
            path: "Tests/SimulatorPoolTestHelpers"
        ),
        .testTarget(
            name: "SimulatorPoolTests",
            dependencies: [
                "CommonTestModels",
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
                "TestDestination",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/SimulatorPoolTests"
        ),
        .target(
            name: "SimulatorVideoRecorder",
            dependencies: [
                "CommonTestModels",
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
                "AppleTestModels",
                "BuildArtifacts",
                "CommonTestModels",
                "DeveloperDirModels",
                "EmceeExtensions",
                "MetricsExtensions",
                "PluginSupport",
                "QueueModels",
                "ScheduleStrategy",
                "SimulatorPoolModels",
                "TestDestination",
                "WorkerCapabilitiesModels",
            ],
            path: "Sources/TestArgFile"
        ),
        .testTarget(
            name: "TestArgFileTests",
            dependencies: [
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                "MetricsExtensions",
                "PluginSupport",
                "QueueModels",
                "ResourceLocation",
                "ScheduleStrategy",
                "SimulatorPoolModels",
                "SimulatorPoolTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                "TestArgFile",
                "TestDestination",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/TestArgFileTests"
        ),
        .target(
            name: "TestDestination",
            dependencies: [
            ],
            path: "Sources/TestDestination"
        ),
        .target(
            name: "TestDestinationTestHelpers",
            dependencies: [
                "TestDestination",
            ],
            path: "Tests/TestDestinationTestHelpers"
        ),
        .testTarget(
            name: "TestDestinationTests",
            dependencies: [
                "EmceeExtensions",
                "TestDestination",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
            ],
            path: "Tests/TestDestinationTests"
        ),
        .target(
            name: "TestDiscovery",
            dependencies: [
                "AppleTestModels",
                "AppleTools",
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "BuildArtifacts",
                "CommonTestModels",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirModels",
                "EmceeLogging",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "Graphite", package: "CommandLineToolkit"),
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
                "AppleTestModelsTestHelpers",
                "BuildArtifacts",
                "BuildArtifactsTestHelpers",
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                .product(name: "DateProvider", package: "CommandLineToolkit"),
                .product(name: "DateProviderTestHelpers", package: "CommandLineToolkit"),
                "DeveloperDirLocator",
                "DeveloperDirLocatorTestHelpers",
                .product(name: "FileSystem", package: "CommandLineToolkit"),
                .product(name: "FileSystemTestHelpers", package: "CommandLineToolkit"),
                "MetricsExtensions",
                .product(name: "PathLib", package: "CommandLineToolkit"),
                "PluginManagerTestHelpers",
                .product(name: "ProcessController", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                "QueueModels",
                "RequestSender",
                "RequestSenderTestHelpers",
                "ResourceLocation",
                "ResourceLocationResolverTestHelpers",
                "RunnerTestHelpers",
                "SimulatorPoolTestHelpers",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                "TestArgFile",
                "TestDiscovery",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                .product(name: "Tmp", package: "CommandLineToolkit"),
                "UniqueIdentifierGenerator",
                "UniqueIdentifierGeneratorTestHelpers",
            ],
            path: "Tests/TestDiscoveryTests"
        ),
        .target(
            name: "TestHistoryModels",
            dependencies: [
                "CommonTestModels",
                "QueueModels",
            ],
            path: "Sources/TestHistoryModels"
        ),
        .target(
            name: "TestHistoryStorage",
            dependencies: [
                "CommonTestModels",
                "QueueModels",
                "TestHistoryModels",
            ],
            path: "Sources/TestHistoryStorage"
        ),
        .target(
            name: "TestHistoryTestHelpers",
            dependencies: [
                "CommonTestModels",
                "CommonTestModelsTestHelpers",
                "QueueModels",
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
                "CommonTestModels",
                "QueueModels",
                "TestDestination",
                "TestHistoryModels",
                "TestHistoryStorage",
                "UniqueIdentifierGenerator",
            ],
            path: "Sources/TestHistoryTracker"
        ),
        .testTarget(
            name: "TestHistoryTrackerTests",
            dependencies: [
                "CommonTestModelsTestHelpers",
                "QueueModels",
                "QueueModelsTestHelpers",
                "SimulatorPoolTestHelpers",
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "TestHistoryModels",
                "TestHistoryStorage",
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
                "EmceeExtensions",
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
            name: "WhatIsMyAddress",
            dependencies: [
                .product(name: "AtomicModels", package: "CommandLineToolkit"),
                "DistWorkerModels",
                "EmceeLogging",
                "QueueModels",
                "RESTInterfaces",
                "RESTMethods",
                "RESTServer",
                "RequestSender",
                .product(name: "SocketModels", package: "CommandLineToolkit"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "SynchronousWaiter", package: "CommandLineToolkit"),
                .product(name: "Types", package: "CommandLineToolkit"),
                "WorkerAlivenessProvider",
            ],
            path: "Sources/WhatIsMyAddress"
        ),
        .target(
            name: "WhatIsMyAddressTestHelpers",
            dependencies: [
                .product(name: "Types", package: "CommandLineToolkit"),
                "WhatIsMyAddress",
            ],
            path: "Sources/WhatIsMyAddressTestHelpers"
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
                "EmceeExtensions",
                "EmceeLogging",
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
        .target(
            name: "Zip",
            dependencies: [
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessController", package: "CommandLineToolkit"),
            ],
            path: "Sources/Zip"
        ),
        .target(
            name: "ZipTestHelpers",
            dependencies: [
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "Zip",
            ],
            path: "Tests/ZipTestHelpers"
        ),
        .testTarget(
            name: "ZipTests",
            dependencies: [
                .product(name: "PathLib", package: "CommandLineToolkit"),
                .product(name: "ProcessControllerTestHelpers", package: "CommandLineToolkit"),
                .product(name: "TestHelpers", package: "CommandLineToolkit"),
                "Zip",
            ],
            path: "Tests/ZipTests"
        ),
    ]
)
