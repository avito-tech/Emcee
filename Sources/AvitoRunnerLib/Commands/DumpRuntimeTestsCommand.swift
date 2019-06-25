import ArgumentsParser
import ChromeTracing
import DistRunner
import EventBus
import Foundation
import JunitReporting
import Logging
import Models
import ResourceLocationResolver
import RuntimeDump
import Scheduler
import ScheduleStrategy
import TempFolder
import Utility
import SimulatorPool

final class DumpRuntimeTestsCommand: Command {
    let command = "dump"
    let overview = "Dumps all available runtime tests into JSON file"
    
    private let fbxctest: OptionArgument<String>
    private let output: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let xctestBundle: OptionArgument<String>
    private let app: OptionArgument<String>
    private let fbsimctl: OptionArgument<String>
    private let resourceLocationResolver = ResourceLocationResolver()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        fbxctest = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        output = subparser.add(stringArgument: KnownStringArguments.output)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        xctestBundle = subparser.add(stringArgument: KnownStringArguments.xctestBundle)
        app = subparser.add(stringArgument: KnownStringArguments.app)
        fbsimctl = subparser.add(stringArgument: KnownStringArguments.fbsimctl)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let fbxctest = try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest)
        let output = try ArgumentsReader.validateNotNil(arguments.get(self.output), key: KnownStringArguments.output)
        let testDestinations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)
        let xctestBundle = try ArgumentsReader.validateResourceLocation(arguments.get(self.xctestBundle), key: KnownStringArguments.xctestBundle)
                
        let applicationTestSupport = getRuntimeDumpApplicationTestSupport(from: arguments)
        let runtimeDumpKind: RuntimeDumpKind = applicationTestSupport != nil ? .appTest : .logicTest

        let configuration = RuntimeDumpConfiguration(
            fbxctest: FbxctestLocation(fbxctest),
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(xctestBundle),
                runtimeDumpKind: runtimeDumpKind
            ),
            applicationTestSupport: applicationTestSupport,
            testDestination: testDestinations[0].testDestination,
            testsToRun: []
        )

        let tempFolder = try TempFolder()
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let runtimeTests = try RuntimeTestQuerierImpl(
            eventBus: EventBus(),
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder
        ).queryRuntime(configuration: configuration)
        let encodedTests = try encoder.encode(runtimeTests.availableRuntimeTests)
        try encodedTests.write(to: URL(fileURLWithPath: output), options: [.atomic])
        Logger.debug("Wrote run time tests dump to file \(output)")
    }

    private func getRuntimeDumpApplicationTestSupport(from arguments: ArgumentParser.Result) -> RuntimeDumpApplicationTestSupport? {
        let fbsimctlPath = try? ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl)
        let appPath = try? ArgumentsReader.validateResourceLocation(arguments.get(self.app), key: KnownStringArguments.app)

        guard appPath != nil else {
            if fbsimctlPath != nil {
                Logger.warning("--fbsimctl argument is unused")
            }

            return nil
        }

        guard let app = appPath, let fbsimctl = fbsimctlPath else {
            Logger.fatal("Both --fbsimctl and --app should be provided or be missing")
        }

        return RuntimeDumpApplicationTestSupport(
            appBundle: AppBundleLocation(app),
            fbsimctl: FbsimctlLocation(fbsimctl)
        )
    }
}
