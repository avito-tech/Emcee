import BuildArtifacts
import DeveloperDirLocator
import Foundation
import Logging
import Models
import PathLib
import PluginManager
import ResourceLocationResolver
import Runner
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import SynchronousWaiter
import TemporaryStuff
import UniqueIdentifierGenerator

public final class RuntimeDumpTestDiscoverer: SpecificTestDiscoverer {
    private let buildArtifacts: BuildArtifacts
    private let developerDirLocator: DeveloperDirLocator
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
    
    public init(
        buildArtifacts: BuildArtifacts,
        developerDirLocator: DeveloperDirLocator,
        numberOfAttemptsToPerformRuntimeDump: UInt,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        pluginEventBusProvider: PluginEventBusProvider,
        resourceLocationResolver: ResourceLocationResolver,
        simulatorControlTool: SimulatorControlTool,
        tempFolder: TemporaryFolder,
        testEntryToQueryRuntimeDump: TestEntry = TestEntry(testName: TestName(className: "NonExistingTest", methodName: "fakeTest"), tags: [], caseId: nil),
        testRunnerProvider: TestRunnerProvider,
        testType: TestType,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDirLocator = developerDirLocator
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
    }
    
    public func discoverTestEntries(
        configuration: TestDiscoveryConfiguration
    ) throws -> [DiscoveredTestEntry] {        
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [uniqueIdentifierGenerator.generate()])
        Logger.debug("Will dump runtime tests into file: \(runtimeEntriesJSONPath)")
        
        let runnerConfiguration = buildRunnerConfiguration(
            buildArtifacts: buildArtifacts,
            configuration: configuration,
            runtimeEntriesJSONPath: runtimeEntriesJSONPath,
            testType: testType
        )
        let runner = Runner(
            configuration: runnerConfiguration,
            developerDirLocator: developerDirLocator,
            pluginEventBusProvider: pluginEventBusProvider,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider
        )
        
        return try runRetrying(times: numberOfAttemptsToPerformRuntimeDump) {
            let allocatedSimulator = try simulatorForTestDiscovery(
                configuration: configuration,
                simulatorControlTool: simulatorControlTool
            )
            defer { allocatedSimulator.releaseSimulator() }
            
            let runnerRunResult = try runner.runOnce(
                entriesToRun: [testEntryToQueryRuntimeDump],
                developerDir: configuration.developerDir,
                simulator: allocatedSimulator.simulator
            )
            
            guard let data = try? Data(contentsOf: runtimeEntriesJSONPath.fileUrl),
                let foundTestEntries = try? JSONDecoder().decode([DiscoveredTestEntry].self, from: data)
                else {
                    runnerRunResult.dumpStandardStreams()
                    throw TestExplorationError.fileNotFound(runtimeEntriesJSONPath)
            }
            
            return foundTestEntries
        }
    }
    
    private func runRetrying<T>(times: UInt, _ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< times {
            do {
                return try work()
            } catch {
                Logger.error("Failed to get runtime dump, error: \(error)")
                SynchronousWaiter().wait(timeout: TimeInterval(retryIndex) * 2.0, description: "Pause between runtime dump retries")
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
            simulatorOperationTimeouts: configuration.simulatorOperationTimeouts
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
