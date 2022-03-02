import AppleTestModels
import BuildArtifacts
import CommonTestModels
import DateProvider
import DeveloperDirLocator
import FileSystem
import Foundation
import EmceeLogging
import Metrics
import MetricsExtensions
import PathLib
import PluginManager
import QueueModels
import ResourceLocationResolver
import Runner
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import SynchronousWaiter
import Tmp
import UniqueIdentifierGenerator

public final class RuntimeDumpTestDiscoverer: SpecificTestDiscoverer {
    private let buildArtifacts: AppleBuildArtifacts
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let pluginEventBusProvider: PluginEventBusProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let runnerWasteCollectorProvider: RunnerWasteCollectorProvider
    private let tempFolder: TemporaryFolder
    private let testEntryToQueryRuntimeDump: TestEntry
    private let testRunnerProvider: TestRunnerProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let version: Version
    private let waiter: Waiter
    private let globalMetricRecorder: GlobalMetricRecorder
    private let specificMetricRecorder: SpecificMetricRecorder
    
    public init(
        buildArtifacts: AppleBuildArtifacts,
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        pluginEventBusProvider: PluginEventBusProvider,
        resourceLocationResolver: ResourceLocationResolver,
        runnerWasteCollectorProvider: RunnerWasteCollectorProvider,
        tempFolder: TemporaryFolder,
        testEntryToQueryRuntimeDump: TestEntry = TestEntry(testName: TestName(className: "NonExistingTest", methodName: "fakeTest"), tags: [], caseId: nil),
        testRunnerProvider: TestRunnerProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        version: Version,
        waiter: Waiter,
        globalMetricRecorder: GlobalMetricRecorder,
        specificMetricRecorder: SpecificMetricRecorder
    ) {
        self.buildArtifacts = buildArtifacts
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.logger = logger
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.pluginEventBusProvider = pluginEventBusProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.runnerWasteCollectorProvider = runnerWasteCollectorProvider
        self.tempFolder = tempFolder
        self.testEntryToQueryRuntimeDump = testEntryToQueryRuntimeDump
        self.testRunnerProvider = testRunnerProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.version = version
        self.waiter = waiter
        self.globalMetricRecorder = globalMetricRecorder
        self.specificMetricRecorder = specificMetricRecorder
    }
    
    public func discoverTestEntries(
        configuration: AppleTestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry] {
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [uniqueIdentifierGenerator.generate()])
        logger.trace("Will write test discovery into file: \(runtimeEntriesJSONPath)")
        
        let runner = AppleRunner(
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            logger: logger,
            pluginEventBusProvider: pluginEventBusProvider,
            runnerWasteCollectorProvider: runnerWasteCollectorProvider,
            specificMetricRecorder: specificMetricRecorder,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            version: version,
            waiter: waiter
        )
        
        let allocatedSimulator = try simulatorForTestDiscovery(
            configuration: configuration
        )
        defer { allocatedSimulator.releaseSimulator() }
        
        _ = try runner.runOnce(
            entriesToRun: [testEntryToQueryRuntimeDump],
            configuration: buildRunnerConfiguration(
                buildArtifacts: buildArtifacts,
                configuration: configuration,
                runtimeEntriesJSONPath: runtimeEntriesJSONPath,
                simulator: allocatedSimulator.simulator
            )
        )
        
        guard fileSystem.properties(forFileAtPath: runtimeEntriesJSONPath).exists() else {
            throw TestExplorationError.fileNotFound(runtimeEntriesJSONPath)
        }
        
        let data = try Data(contentsOf: runtimeEntriesJSONPath.fileUrl)
        return try JSONDecoder().decode([DiscoveredTestEntry].self, from: data)
    }
    
    private func buildRunnerConfiguration(
        buildArtifacts: AppleBuildArtifacts,
        configuration: AppleTestDiscoveryConfiguration,
        runtimeEntriesJSONPath: AbsolutePath,
        simulator: Simulator
    ) -> AppleRunnerConfiguration {
        return AppleRunnerConfiguration(
            appleTestConfiguration: configuration.testConfiguration,
            lostTestProcessingMode: .reportLost,
            persistentMetricsJobId: configuration.analyticsConfiguration.persistentMetricsJobId,
            simulator: simulator
        )
    }

    private func simulatorForTestDiscovery(
        configuration: AppleTestDiscoveryConfiguration
    ) throws -> AllocatedSimulator {
        let simulatorPool = try onDemandSimulatorPool.pool(
            key: configuration.testConfiguration.onDemandSimulatorPoolKey
        )
        return try simulatorPool.allocateSimulator(
            dateProvider: dateProvider,
            logger: logger,
            simulatorOperationTimeouts: configuration.testConfiguration.simulatorOperationTimeouts,
            version: version,
            globalMetricRecorder: globalMetricRecorder
        )
    }
    
    private func environment(
        configuration: AppleTestDiscoveryConfiguration,
        runtimeEntriesJSONPath: AbsolutePath
    ) -> [String: String] {
        var environment = configuration.testConfiguration.testExecutionBehavior.environment
        environment["EMCEE_RUNTIME_TESTS_EXPORT_PATH"] = runtimeEntriesJSONPath.pathString
        return environment
    }
}
