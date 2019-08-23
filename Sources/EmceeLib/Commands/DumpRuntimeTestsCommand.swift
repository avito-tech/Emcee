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
import Utility

final class DumpRuntimeTestsCommand: SPMCommand {
    let command = "dump"
    let overview = "Dumps all available runtime tests into JSON file"
    
    private let fbxctest: OptionArgument<String>
    private let output: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let xctestBundle: OptionArgument<String>
    private let app: OptionArgument<String>
    private let fbsimctl: OptionArgument<String>
    private let tempFolder: OptionArgument<String>
    private let encoder = JSONEncoder.pretty()
    private let resourceLocationResolver = ResourceLocationResolver()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        fbxctest = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        output = subparser.add(stringArgument: KnownStringArguments.output)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        xctestBundle = subparser.add(stringArgument: KnownStringArguments.xctestBundle)
        app = subparser.add(stringArgument: KnownStringArguments.app)
        fbsimctl = subparser.add(stringArgument: KnownStringArguments.fbsimctl)
        tempFolder = subparser.add(stringArgument: KnownStringArguments.tempFolder)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let testRunnerTool = TestRunnerTool.fbxctest(
            FbxctestLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest))
        )
        let output = try ArgumentsReader.validateNotNil(arguments.get(self.output), key: KnownStringArguments.output)
        let testDestinations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)
        let xctestBundle = try ArgumentsReader.validateResourceLocation(arguments.get(self.xctestBundle), key: KnownStringArguments.xctestBundle)
                
        let applicationTestSupport = getRuntimeDumpApplicationTestSupport(from: arguments)
        let runtimeDumpKind: RuntimeDumpKind = applicationTestSupport != nil ? .appTest : .logicTest

        let configuration = RuntimeDumpConfiguration(
            testRunnerTool: testRunnerTool,
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(xctestBundle),
                runtimeDumpKind: runtimeDumpKind
            ),
            applicationTestSupport: applicationTestSupport,
            testDestination: testDestinations[0].testDestination,
            testsToValidate: [],
            developerDir: DeveloperDir.current
        )

        let tempFolder = try TemporaryFolder(
            containerPath: AbsolutePath(
                try ArgumentsReader.validateNotNil(
                    arguments.get(self.tempFolder), key: KnownStringArguments.tempFolder
                )
            )
        )
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let runtimeTests = try RuntimeTestQuerierImpl(
            eventBus: EventBus(),
            numberOfAttemptsToPerformRuntimeDump: 5,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder,
            testRunnerProvider: DefaultTestRunnerProvider(
                resourceLocationResolver: resourceLocationResolver
            )
        ).queryRuntime(configuration: configuration)
        let encodedTests = try encoder.encode(runtimeTests.availableRuntimeTests)
        try encodedTests.write(to: URL(fileURLWithPath: output), options: [.atomic])
        Logger.debug("Wrote run time tests dump to file \(output)")
    }

    private func getRuntimeDumpApplicationTestSupport(from arguments: ArgumentParser.Result) -> RuntimeDumpApplicationTestSupport? {
        let fbsimctlLocation = try? ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl)
        let appPath = try? ArgumentsReader.validateResourceLocation(arguments.get(self.app), key: KnownStringArguments.app)

        guard appPath != nil else {
            if fbsimctlLocation != nil {
                Logger.warning("--fbsimctl argument is unused")
            }

            return nil
        }

        guard let app = appPath, let fbsimctl = fbsimctlLocation else {
            Logger.fatal("Both --fbsimctl and --app should be provided or be missing")
        }

        return RuntimeDumpApplicationTestSupport(
            appBundle: AppBundleLocation(app),
            simulatorControlTool: SimulatorControlTool.fbsimctl(FbsimctlLocation(fbsimctl))
        )
    }
}
