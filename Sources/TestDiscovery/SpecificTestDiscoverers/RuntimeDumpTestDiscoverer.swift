import BuildArtifacts
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

final class RuntimeDumpTestDiscoverer: SpecificTestDiscoverer {
    private let buildArtifacts: BuildArtifacts
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
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
    
    init(
        buildArtifacts: BuildArtifacts,
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
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
    
    func discoverTestEntries(
        configuration: TestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry] {
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [uniqueIdentifierGenerator.generate()])
        configuration.logger.debug("Will dump runtime tests into file: \(runtimeEntriesJSONPath)")
        
        let runnerConfiguration = buildRunnerConfiguration(
            buildArtifacts: buildArtifacts,
            configuration: configuration,
            runtimeEntriesJSONPath: runtimeEntriesJSONPath
        )
        let runner = Runner(
            configuration: runnerConfiguration,
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            logger: configuration.logger,
            persistentMetricsJobId: configuration.analyticsConfiguration.persistentMetricsJobId,
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
            developerDir: configuration.developerDir,
            simulator: allocatedSimulator.simulator,
            lostTestProcessingMode: .reportError
        )
        
        guard fileSystem.properties(forFileAtPath: runtimeEntriesJSONPath).exists() else {
            throw TestExplorationError.fileNotFound(runtimeEntriesJSONPath)
        }
        
        let data = try Data(contentsOf: runtimeEntriesJSONPath.fileUrl)
        return try JSONDecoder().decode([DiscoveredTestEntry].self, from: data)
    }
    
    private func buildRunnerConfiguration(
        buildArtifacts: BuildArtifacts,
        configuration: TestDiscoveryConfiguration,
        runtimeEntriesJSONPath: AbsolutePath
    ) -> RunnerConfiguration {
        return RunnerConfiguration(
            buildArtifacts: buildArtifacts,
            environment: environment(
                configuration: configuration,
                runtimeEntriesJSONPath: runtimeEntriesJSONPath
            ),
            pluginLocations: configuration.pluginLocations,
            simulatorSettings: configuration.simulatorSettings,
            testTimeoutConfiguration: configuration.testTimeoutConfiguration
        )
    }

    private func simulatorForTestDiscovery(
        configuration: TestDiscoveryConfiguration
    ) throws -> AllocatedSimulator {
        let simulatorPool = try onDemandSimulatorPool.pool(
            key: OnDemandSimulatorPoolKey(
                developerDir: configuration.developerDir,
                testDestination: configuration.testDestination
            )
        )
        return try simulatorPool.allocateSimulator(
            dateProvider: dateProvider,
            logger: configuration.logger,
            simulatorOperationTimeouts: configuration.simulatorOperationTimeouts,
            version: version,
            globalMetricRecorder: globalMetricRecorder
        )
    }
    
    private func environment(
        configuration: TestDiscoveryConfiguration,
        runtimeEntriesJSONPath: AbsolutePath
    ) -> [String: String] {
        var environment = configuration.testExecutionBehavior.environment
        environment["EMCEE_RUNTIME_TESTS_EXPORT_PATH"] = runtimeEntriesJSONPath.pathString
        return environment
    }
}
