import ArgLib
import ChromeTracing
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
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(resourceLocationResolver: ResourceLocationResolver) {
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
        let applicationTestSupport = try runtimeDumpApplicationTestSupport(payload: payload)
        let runtimeDumpKind: RuntimeDumpKind = applicationTestSupport != nil ? .appTest : .logicTest
        let tempFolder = try TemporaryFolder(
            containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name)
        )
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)

        let configuration = RuntimeDumpConfiguration(
            testRunnerTool: testRunnerTool,
            xcTestBundle: XcTestBundle(
                location: xctestBundle,
                runtimeDumpKind: runtimeDumpKind
            ),
            applicationTestSupport: applicationTestSupport,
            testDestination: testDestinations[0].testDestination,
            testsToValidate: [],
            developerDir: DeveloperDir.current
        )
        
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }

        let runtimeTestQuerier = RuntimeTestQuerierImpl(
            eventBus: EventBus(),
            numberOfAttemptsToPerformRuntimeDump: 5,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder,
            testRunnerProvider: DefaultTestRunnerProvider(
                resourceLocationResolver: resourceLocationResolver
            )
        )
        let runtimeTests = try runtimeTestQuerier.queryRuntime(configuration: configuration)
        
        let encodedTests = try encoder.encode(runtimeTests.availableRuntimeTests)
        try encodedTests.write(to: outputPath.fileUrl, options: [.atomic])
        Logger.debug("Wrote run time tests dump to file \(outputPath)")
    }
        
    private func runtimeDumpApplicationTestSupport(
        payload: CommandPayload
    ) throws -> RuntimeDumpApplicationTestSupport? {
        let fbsimctlLocation: FbsimctlLocation? = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.fbsimctl.name)
        let app: AppBundleLocation? = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.app.name)

        guard let appLocation = app else {
            if fbsimctlLocation != nil {
                Logger.warning("--fbsimctl argument is unused")
            }
            return nil
        }

        guard let fbsimctl = fbsimctlLocation else {
            Logger.fatal("To perform runtime dump in application test mode, both --fbsimctl and --app arguments should be provided. Omit both arguments to perform runtime dump in logic test mode.")
        }

        return RuntimeDumpApplicationTestSupport(
            appBundle: appLocation,
            simulatorControlTool: SimulatorControlTool.fbsimctl(fbsimctl)
        )
    }
}
