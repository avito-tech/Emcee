import ArgLib
import ChromeTracing
import DateProvider
import DeveloperDirLocator
import EventBus
import Extensions
import FileSystem
import Foundation
import Logging
import Models
import PathLib
import PluginManager
import ProcessController
import ResourceLocationResolver
import ScheduleStrategy
import Scheduler
import SignalHandling
import SimulatorPool
import TemporaryStuff
import TestDiscovery
import UniqueIdentifierGenerator

public final class DumpCommand: Command {
    public let name = "dump"
    public let description = "Performs test discovery and dumps information about discovered tests into JSON file"
    public let arguments: Arguments = [
        ArgumentDescriptions.output.asRequired,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.remoteCacheConfig.asOptional,
    ]
    
    private let encoder = JSONEncoder.pretty()
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let pluginEventBusProvider: PluginEventBusProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let runtimeDumpRemoteCacheProvider: RuntimeDumpRemoteCacheProvider
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        pluginEventBusProvider: PluginEventBusProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        runtimeDumpRemoteCacheProvider: RuntimeDumpRemoteCacheProvider

    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.pluginEventBusProvider = pluginEventBusProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.runtimeDumpRemoteCacheProvider = runtimeDumpRemoteCacheProvider
    }

    public func run(payload: CommandPayload) throws {
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        let remoteCacheConfig = try ArgumentsReader.remoteCacheConfig(
            try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.remoteCacheConfig.name)
        )
        let tempFolder = try TemporaryFolder(
            containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name)
        )
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)
        
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        SignalHandling.addSignalHandler(signals: [.term, .int]) { signal in
            Logger.debug("Got signal: \(signal)")
            onDemandSimulatorPool.deleteSimulators()
        }
        
        let dumpedTests: [[DiscoveredTestEntry]] = try testArgFile.entries.map { testArgFileEntry -> [DiscoveredTestEntry] in
            let configuration = TestDiscoveryConfiguration(
                developerDir: testArgFileEntry.developerDir,
                pluginLocations: testArgFileEntry.pluginLocations,
                testDiscoveryMode: try TestDiscoveryModeDeterminer.testDiscoveryMode(testArgFileEntry: testArgFileEntry),
                simulatorOperationTimeouts: testArgFileEntry.simulatorOperationTimeouts,
                simulatorSettings: testArgFileEntry.simulatorSettings,
                testDestination: testArgFileEntry.testDestination,
                testExecutionBehavior: TestExecutionBehavior(
                    environment: testArgFileEntry.environment,
                    numberOfRetries: testArgFileEntry.numberOfRetries
                ),
                testRunnerTool: testArgFileEntry.testRunnerTool,
                testTimeoutConfiguration: testTimeoutConfigurationForRuntimeDump,
                testsToValidate: testArgFileEntry.testsToRun,
                xcTestBundleLocation: testArgFileEntry.buildArtifacts.xcTestBundle.location
            )

            let testDiscoveryQuerier = TestDiscoveryQuerierImpl(
                dateProvider: dateProvider,
                developerDirLocator: developerDirLocator,
                fileSystem: fileSystem,
                numberOfAttemptsToPerformRuntimeDump: testArgFileEntry.numberOfRetries,
                onDemandSimulatorPool: onDemandSimulatorPool,
                pluginEventBusProvider: pluginEventBusProvider,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver,
                tempFolder: tempFolder,
                testRunnerProvider: DefaultTestRunnerProvider(
                    dateProvider: dateProvider,
                    processControllerProvider: processControllerProvider,
                    resourceLocationResolver: resourceLocationResolver
                ),
                uniqueIdentifierGenerator: uniqueIdentifierGenerator,
                remoteCache: runtimeDumpRemoteCacheProvider.remoteCache(config: remoteCacheConfig)
            )
            
            let result = try testDiscoveryQuerier.query(configuration: configuration)
            Logger.debug("Test bundle \(testArgFileEntry.buildArtifacts.xcTestBundle) contains \(result.discoveredTests.tests.count) tests")
            return result.discoveredTests.tests
        }
        
        let encodedResult = try encoder.encode(dumpedTests)
        try encodedResult.write(to: outputPath.fileUrl, options: [.atomic])
        Logger.debug("Wrote run time tests dump to file \(outputPath)")
    }
}
