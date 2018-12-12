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

final class DumpRuntimeTestsCommand: Command {
    let command = "dump"
    let overview = "Dumps all available runtime tests into JSON file"
    
    private let fbxctest: OptionArgument<String>
    private let output: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let xctestBundle: OptionArgument<String>
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
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let fbxctest = try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest)
        let output = try ArgumentsReader.validateNotNil(arguments.get(self.output), key: KnownStringArguments.output)
        let testDestinations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)
        let xctestBundle = try ArgumentsReader.validateResourceLocation(arguments.get(self.xctestBundle), key: KnownStringArguments.xctestBundle)
                
        let configuration = RuntimeDumpConfiguration(
            fbxctest: FbxctestLocation(fbxctest),
            xcTestBundle: TestBundleLocation(xctestBundle),
            testDestination: testDestinations[0].testDestination,
            testsToRun: []
        )
        
        let runtimeTests = try RuntimeTestQuerier(
            eventBus: EventBus(),
            configuration: configuration,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: try TempFolder())
            .queryRuntime()
        let encodedTests = try encoder.encode(runtimeTests.availableRuntimeTests)
        try encodedTests.write(to: URL(fileURLWithPath: output), options: [.atomic])
        log("Wrote run time tests dump to file \(output)")
    }
}
