import ArgLib
import ChromeTracing
import DeveloperDirLocator
import EventBus
import Extensions
import Foundation
import JunitReporting
import Logging
import Models
import PathLib
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
    private let developerDirLocator: DeveloperDirLocator
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        developerDirLocator: DeveloperDirLocator,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.developerDirLocator = developerDirLocator
        self.resourceLocationResolver = resourceLocationResolver
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
            tempFolder: tempFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let dumpedTests: [[RuntimeTestEntry]] = try testArgFile.entries.map { testArgFileEntry -> [RuntimeTestEntry] in
            let configuration = RuntimeDumpConfiguration(
                developerDir: testArgFileEntry.toolchainConfiguration.developerDir,
                runtimeDumpMode: try RuntimeDumpModeDeterminer.runtimeDumpMode(testArgFileEntry: testArgFileEntry),
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
                eventBus: EventBus(),
                developerDirLocator: developerDirLocator,
                numberOfAttemptsToPerformRuntimeDump: testArgFileEntry.numberOfRetries,
                onDemandSimulatorPool: onDemandSimulatorPool,
                resourceLocationResolver: resourceLocationResolver,
                tempFolder: tempFolder,
                testRunnerProvider: DefaultTestRunnerProvider(resourceLocationResolver: resourceLocationResolver),
                uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator()
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
