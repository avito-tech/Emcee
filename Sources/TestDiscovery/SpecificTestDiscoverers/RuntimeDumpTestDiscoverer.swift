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
    private let numberOfAttemptsToPerformRuntimeDump: UInt
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let pluginEventBusProvider: PluginEventBusProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let simulatorControlTool: SimulatorControlTool
    private let tempFolder: TemporaryFolder
    private let testEntryToQueryRuntimeDump: TestEntry
    private let testRunnerProvider: TestRunnerProvider
    private let testType: TestType
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
        numberOfAttemptsToPerformRuntimeDump: UInt,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        pluginEventBusProvider: PluginEventBusProvider,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorControlTool: SimulatorControlTool,
        tempFolder: TemporaryFolder,
        testEntryToQueryRuntimeDump: TestEntry = TestEntry(testName: TestName(className: "NonExistingTest", methodName: "fakeTest"), tags: [], caseId: nil),
        testRunnerProvider: TestRunnerProvider,
        testType: TestType,
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
        self.numberOfAttemptsToPerformRuntimeDump = max(numberOfAttemptsToPerformRuntimeDump, 1)
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.pluginEventBusProvider = pluginEventBusProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.simulatorControlTool = simulatorControlTool
        self.tempFolder = tempFolder
        self.testEntryToQueryRuntimeDump = testEntryToQueryRuntimeDump
        self.testRunnerProvider = testRunnerProvider
        self.testType = testType
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
            runtimeEntriesJSONPath: runtimeEntriesJSONPath,
            testType: testType
        )
        let runner = Runner(
            configuration: runnerConfiguration,
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            logger: configuration.logger,
            persistentMetricsJobId: configuration.analyticsConfiguration.persistentMetricsJobId,
            pluginEventBusProvider: pluginEventBusProvider,
            resourceLocationResolver: resourceLocationResolver,
            specificMetricRecorder: specificMetricRecorder,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            version: version,
            waiter: waiter
        )
        
        return try runRetrying(logger: configuration.logger, times: numberOfAttemptsToPerformRuntimeDump) {
            let allocatedSimulator = try simulatorForTestDiscovery(
                configuration: configuration,
                simulatorControlTool: simulatorControlTool
            )
            defer { allocatedSimulator.releaseSimulator() }
            
            _ = try runner.runOnce(
                entriesToRun: [testEntryToQueryRuntimeDump],
                developerDir: configuration.developerDir,
                simulator: allocatedSimulator.simulator
            )
            
            guard let data = try? Data(contentsOf: runtimeEntriesJSONPath.fileUrl),
                let foundTestEntries = try? JSONDecoder().decode([DiscoveredTestEntry].self, from: data)
                else {
                    throw TestExplorationError.fileNotFound(runtimeEntriesJSONPath)
            }
            
            return foundTestEntries
        }
    }
    
    private func runRetrying<T>(logger: ContextualLogger, times: UInt, _ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< times {
            do {
                return try work()
            } catch {
                logger.error("Failed to get runtime dump, error: \(error)")
                waiter.wait(timeout: TimeInterval(retryIndex) * 2.0, description: "Pause between runtime dump retries")
            }
        }
        return try work()
    }
    
    private func buildRunnerConfiguration(
        buildArtifacts: BuildArtifacts,
        configuration: TestDiscoveryConfiguration,
        runtimeEntriesJSONPath: AbsolutePath,
        testType: TestType
    ) -> RunnerConfiguration {
        return RunnerConfiguration(
            buildArtifacts: buildArtifacts,
            environment: environment(
                configuration: configuration,
                runtimeEntriesJSONPath: runtimeEntriesJSONPath
            ),
            pluginLocations: configuration.pluginLocations,
            simulatorSettings: configuration.simulatorSettings,
            testRunnerTool: configuration.testRunnerTool,
            testTimeoutConfiguration: configuration.testTimeoutConfiguration,
            testType: testType
        )
    }

    private func simulatorForTestDiscovery(
        configuration: TestDiscoveryConfiguration,
        simulatorControlTool: SimulatorControlTool
    ) throws -> AllocatedSimulator {
        let simulatorPool = try onDemandSimulatorPool.pool(
            key: OnDemandSimulatorPoolKey(
                developerDir: configuration.developerDir,
                testDestination: configuration.testDestination,
                simulatorControlTool: simulatorControlTool
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
