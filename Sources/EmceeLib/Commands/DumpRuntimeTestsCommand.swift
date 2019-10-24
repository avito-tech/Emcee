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
        ArgumentDescriptions.app.asOptional,
        ArgumentDescriptions.fbsimctl.asOptional,
        ArgumentDescriptions.fbxctest.asRequired,
        ArgumentDescriptions.output.asRequired,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testDestinations.asRequired,
        ArgumentDescriptions.xctestBundle.asRequired,
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
        let testRunnerTool: TestRunnerTool = .fbxctest(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.fbxctest.name)
        )
        let testDestinations: [TestDestinationConfiguration] = try ArgumentsReader.testDestinations(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testDestinations.name)
        )
        let xctestBundle: TestBundleLocation = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.xctestBundle.name)
        let runtimeDumpMode = try determineDumpMode(payload: payload)
        let tempFolder = try TemporaryFolder(
            containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name)
        )
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)

        let configuration = RuntimeDumpConfiguration(
            testRunnerTool: testRunnerTool,
            xcTestBundleLocation: xctestBundle,
            runtimeDumpMode: runtimeDumpMode,
            testDestination: testDestinations[0].testDestination,
            testsToValidate: [],
            developerDir: DeveloperDir.current
        )
        
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            developerDirLocator: developerDirLocator,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }

        let runtimeTestQuerier = RuntimeTestQuerierImpl(
            eventBus: EventBus(),
            developerDirLocator: developerDirLocator,
            numberOfAttemptsToPerformRuntimeDump: 5,
            onDemandSimulatorPool: onDemandSimulatorPool,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: DefaultTestRunnerProvider(resourceLocationResolver: resourceLocationResolver),
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator()
        )
        let runtimeTests = try runtimeTestQuerier.queryRuntime(configuration: configuration)
        
        let encodedTests = try encoder.encode(runtimeTests.availableRuntimeTests)
        try encodedTests.write(to: outputPath.fileUrl, options: [.atomic])
        Logger.debug("Wrote run time tests dump to file \(outputPath)")
    }
        
    private func determineDumpMode(payload: CommandPayload) throws -> RuntimeDumpMode {
        let app: AppBundleLocation? = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.app.name)

        guard let appLocation = app else {
            return .logicTest
        }

        let fbsimctlLocation: FbsimctlLocation = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.fbsimctl.name)

        return .appTest(
            RuntimeDumpApplicationTestSupport(
                appBundle: appLocation,
                simulatorControlTool: .fbsimctl(fbsimctlLocation)
            )
        )
    }
}
