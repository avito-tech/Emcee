import ArgumentsParser
import ChromeTracing
import DistRun
import Foundation
import JunitReporting
import Logging
import ModelFactories
import Models
import RuntimeDump
import Scheduler
import ScheduleStrategy
import Utility

final class DumpRuntimeTestsCommand: Command {
    let command = "dump"
    let overview = "Dumps all available runtime tests into JSON file"
    
    private let fbxctestValue: OptionArgument<String>
    private let output: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let xctestBundle: OptionArgument<String>
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        fbxctestValue = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        output = subparser.add(stringArgument: KnownStringArguments.output)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        xctestBundle = subparser.add(stringArgument: KnownStringArguments.xctestBundle)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let fileManager = FileManager.default
        let decoder = JSONDecoder()
        guard let fbxctestValue = arguments.get(fbxctestValue) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.fbxctest)
        }
        guard let output = arguments.get(output) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.output)
        }
        guard let testDestinationFile = arguments.get(self.testDestinations) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.testDestinations)
        }
        let testDestinationConfigurations: [TestDestinationConfiguration]
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: testDestinationFile))
            testDestinationConfigurations = try decoder.decode([TestDestinationConfiguration].self, from: data)
        } catch {
            throw ArgumentsError.argumentValueCannotBeUsed(KnownStringArguments.testDestinations, error)
        }
        guard let xcTestBundle = arguments.get(xctestBundle), fileManager.fileExists(atPath: xcTestBundle) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.xctestBundle)
        }
        
        let resolver = ResourceLocationResolver.sharedResolver
        let fbxctest = try resolver.resolvePath(resourceLocation: .from(fbxctestValue)).with(archivedFile: "fbxctest")
        
        let configuration = RuntimeDumpConfiguration(
            fbxctest: fbxctest,
            xcTestBundle: xcTestBundle,
            simulatorSettings: SimulatorSettings(simulatorLocalizationSettings: "", watchdogSettings: ""),
            testDestination: testDestinationConfigurations[0].testDestination,
            testsToRun: [])
        
        let runtimeTests = try RuntimeTestQuerier(configuration: configuration).queryRuntime()
        let encodedTests = try encoder.encode(runtimeTests.availableRuntimeTests)
        try encodedTests.write(to: URL(fileURLWithPath: output), options: [.atomic])
        log("Wrote run time tests dump to file \(output)")
    }
}
