import ArgLib
import ChromeTracing
import DateProvider
import DeveloperDirLocator
import EventBus
import Extensions
import Foundation
import JunitReporting
import Logging
import Models
import PathLib
import PluginManager
import ResourceLocationResolver
import RuntimeDump
import ScheduleStrategy
import Scheduler
import SimulatorPool
import TemporaryStuff
import UniqueIdentifierGenerator

public final class DumpRuntimeTestsCommand: Command {
    public let name = "dump"
    public let description = "Dumps all available runtime tests into JSON file"
    public let arguments: Arguments = [
        ArgumentDescriptions.output.asRequired,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
    ]
    
    private let encoder = JSONEncoder.pretty()
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let pluginEventBusProvider: PluginEventBusProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        pluginEventBusProvider: PluginEventBusProvider,
        resourceLocationResolver: ResourceLocationResolver,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.pluginEventBusProvider = pluginEventBusProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }

    public func run(payload: CommandPayload) throws {
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        let tempFolder = try TemporaryFolder(
            containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name)
        )
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)
        
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            developerDirLocator: developerDirLocator,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let dumpedTests: [[RuntimeTestEntry]] = try testArgFile.entries.map { testArgFileEntry -> [RuntimeTestEntry] in
            let configuration = RuntimeDumpConfiguration(
                developerDir: testArgFileEntry.toolchainConfiguration.developerDir,
                pluginLocations: testArgFileEntry.pluginLocations,
                runtimeDumpMode: try RuntimeDumpModeDeterminer.runtimeDumpMode(testArgFileEntry: testArgFileEntry),
                simulatorSettings: testArgFileEntry.simulatorSettings,
                testDestination: testArgFileEntry.testDestination,
                testExecutionBehavior: TestExecutionBehavior(
                    environment: testArgFileEntry.environment,
                    numberOfRetries: testArgFileEntry.numberOfRetries
                ),
                testRunnerTool: testArgFileEntry.toolResources.testRunnerTool,
                testTimeoutConfiguration: testTimeoutConfigurationForRuntimeDump,
                testsToValidate: testArgFileEntry.testsToRun,
                xcTestBundleLocation: testArgFileEntry.buildArtifacts.xcTestBundle.location
            )
            
            let runtimeTestQuerier = RuntimeTestQuerierImpl(

                developerDirLocator: developerDirLocator,
                numberOfAttemptsToPerformRuntimeDump: testArgFileEntry.numberOfRetries,
                onDemandSimulatorPool: onDemandSimulatorPool,
                pluginEventBusProvider: pluginEventBusProvider,
                resourceLocationResolver: resourceLocationResolver,
                tempFolder: tempFolder,
                testRunnerProvider: DefaultTestRunnerProvider(
                    dateProvider: dateProvider,
                    resourceLocationResolver: resourceLocationResolver
                ),
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            )
            
            let result = try runtimeTestQuerier.queryRuntime(configuration: configuration)
            Logger.debug("Test bundle \(testArgFileEntry.buildArtifacts.xcTestBundle) contains \(result.availableRuntimeTests.count) tests")
            return result.availableRuntimeTests
        }
        
        let encodedResult = try encoder.encode(dumpedTests)
        try encodedResult.write(to: outputPath.fileUrl, options: [.atomic])
        Logger.debug("Wrote run time tests dump to file \(outputPath)")
    }
}
