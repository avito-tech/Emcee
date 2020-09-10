import ArgLib
import ChromeTracing
import DateProvider
import DeveloperDirLocator
import DI
import EmceeVersion
import FileSystem
import Foundation
import Logging
import PathLib
import PluginManager
import ProcessController
import QueueModels
import ResourceLocationResolver
import RunnerModels
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
        ArgumentDescriptions.emceeVersion.asOptional,
        ArgumentDescriptions.output.asRequired,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.remoteCacheConfig.asOptional,
    ]
    
    private let encoder = JSONEncoder.pretty()
    private let di: DI
    
    public init(di: DI) {
        self.di = di
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
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        
        let onDemandSimulatorPool = try OnDemandSimulatorPoolFactory.create(
            di: di,
            version: emceeVersion
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
                xcTestBundleLocation: testArgFileEntry.buildArtifacts.xcTestBundle.location,
                persistentMetricsJobId: testArgFile.persistentMetricsJobId
            )

            let testDiscoveryQuerier = TestDiscoveryQuerierImpl(
                dateProvider: try di.get(),
                developerDirLocator: try di.get(),
                fileSystem: try di.get(),
                numberOfAttemptsToPerformRuntimeDump: testArgFileEntry.numberOfRetries,
                onDemandSimulatorPool: try di.get(),
                pluginEventBusProvider: try di.get(),
                processControllerProvider: try di.get(),
                remoteCache: try di.get(RuntimeDumpRemoteCacheProvider.self).remoteCache(config: remoteCacheConfig),
                resourceLocationResolver: try di.get(),
                tempFolder: tempFolder,
                testRunnerProvider: DefaultTestRunnerProvider(
                    dateProvider: try di.get(),
                    processControllerProvider: try di.get(),
                    resourceLocationResolver: try di.get()
                ),
                uniqueIdentifierGenerator: try di.get(),
                version: emceeVersion
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
