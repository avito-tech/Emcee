import Foundation
import Logging
import Models
import Utility

protocol ArgumentDescription {
    var name: String { get }
    var comment: String { get }
    var multiple: Bool { get }
    var optional: Bool { get }
}

extension ArgumentDescription {
    var usage: String {
        var usage = comment
        if usage.last != "." {
            usage += "."
        }
        if multiple {
            usage += " This argument may be repeated multiple times."
        }
        if optional {
            usage += " Optional."
        }
        return usage
    }
}

enum ArgumentType {
    case string
    case int
    case bool
}

private struct ArgumentDescriptionHolder: ArgumentDescription {
    let name: String
    let comment: String
    let multiple: Bool
    let optional: Bool
    
    init(name: String, comment: String, multiple: Bool = false, optional: Bool = false) {
        self.name = name
        self.comment = comment
        self.multiple = multiple
        self.optional = optional
    }
}

private let knownStringArguments: [KnownStringArguments: ArgumentDescriptionHolder] = [
    KnownStringArguments.app: ArgumentDescriptionHolder(
        name: "--app",
        comment: "Location of app that will be tested by the UI tests. If value is missing, tests can be executed only as logic tests",
        optional: true),
    KnownStringArguments.analyticsConfiguration: ArgumentDescriptionHolder(
        name: "--analytics-configuration",
        comment: "Location of analytics configuration JSON file to support various analytic destinations",
        optional: true),
    KnownStringArguments.destinationConfigurations: ArgumentDescriptionHolder(
        name: "--destinaton-configurations",
        comment: "A JSON file with additional configuration per destination",
        optional: true),
    KnownStringArguments.destinations: ArgumentDescriptionHolder(
        name: "--destinations",
        comment: "A JSON file with info about the run destinations for distributed test run"),
    KnownStringArguments.fbsimctl: ArgumentDescriptionHolder(
        name: "--fbsimctl",
        comment: "Location of fbsimctl tool, or URL to ZIP archive"),
    KnownStringArguments.fbxctest: ArgumentDescriptionHolder(
        name: "--fbxctest",
        comment: "Location of fbxctest tool, or URL to ZIP archive"),
    KnownStringArguments.junit: ArgumentDescriptionHolder(
        name: "--junit",
        comment: "Where the combined (the one for all test destinations) Junit report should be created",
        optional: true),
    KnownStringArguments.output: ArgumentDescriptionHolder(
        name: "--output",
        comment: "Path to where should output be stored as JSON file"),
    KnownStringArguments.plugin: ArgumentDescriptionHolder(
        name: "--plugin",
        comment: ".emceeplugin bundle location (or URL to ZIP). Plugin bundle should contain an executable: MyPlugin.emceeplugin/Plugin",
        multiple: true,
        optional: true),
    KnownStringArguments.queueServer: ArgumentDescriptionHolder(
        name: "--queue-server",
        comment: "An address to a server which runs distRun command, e.g. 127.0.0.1:1234"),
    KnownStringArguments.queueServerDestination: ArgumentDescriptionHolder(
        name: "--queue-server-destination",
        comment: "A JSON file with info about deployment destination which will be used to start remote queue server"),
    KnownStringArguments.queueServerRunConfigurationLocation: ArgumentDescriptionHolder(
        name: "--queue-server-run-configuration-location",
        comment: "JSON file location which describes QueueServerRunConfiguration. Either /path/to/file.json, or http://example.com/file.zip#path/to/config.json"),
    KnownStringArguments.remoteScheduleStrategy: ArgumentDescriptionHolder(
        name: "--remote-schedule-strategy",
        comment: "Defines how to scatter tests to the destination machines. Can be: \(ScheduleStrategyType.availableRawValues.joined(separator: ", "))"),
    KnownStringArguments.runId: ArgumentDescriptionHolder(
        name: "--run-id",
        comment: "A logical test run id, usually a random string, e.g. UUID."),
    KnownStringArguments.scheduleStrategy: ArgumentDescriptionHolder(
        name: "--schedule-strategy",
        comment: "Defines how to run tests. Can be: \(ScheduleStrategyType.availableRawValues.joined(separator: ", "))"),
    KnownStringArguments.simulatorLocalizationSettings: ArgumentDescriptionHolder(
        name: "--simulator-localization-settings",
        comment: "Location of JSON file with localization settings",
        optional: true),
    KnownStringArguments.tempFolder: ArgumentDescriptionHolder(
        name: "--temp-folder",
        comment: "Where to store temporary stuff, including simulator data"),
    KnownStringArguments.testArgFile: ArgumentDescriptionHolder(
        name: "--test-arg-file",
        comment: "JSON file with description of all tests that expected to be ran.",
        optional: true),
    KnownStringArguments.testDestinations: ArgumentDescriptionHolder(
        name: "--test-destinations",
        comment: "A JSON file with test destination configurations. For runtime dump only first destination will be used."),
    KnownStringArguments.trace: ArgumentDescriptionHolder(
        name: "--trace",
        comment: "Where the combined (the one for all test destinations) Chrome trace should be created",
        optional: true),
    KnownStringArguments.watchdogSettings: ArgumentDescriptionHolder(
        name: "--watchdog-settings",
        comment: "Location of JSON file with watchdog settings",
        optional: true),
    KnownStringArguments.workerId: ArgumentDescriptionHolder(
        name: "--worker-id",
        comment: "An identifier used to distinguish between workers. Useful to match with deployment destination's identifier"),
    KnownStringArguments.xctestBundle: ArgumentDescriptionHolder(
        name: "--xctest-bundle",
        comment: "Location of .xctest bundle with your tests"),
]

private let knownUIntArguments: [KnownUIntArguments: ArgumentDescriptionHolder] = [
    KnownUIntArguments.testRunnerSilenceTimeout: ArgumentDescriptionHolder(
        name: "--test-runner-silence-timeout",
        comment: "A maximum allowed duration for a test runner stdout/stderr to be silent",
        optional: true),
    KnownUIntArguments.numberOfSimulators: ArgumentDescriptionHolder(
        name: "--number-of-simulators",
        comment: "How many simlutors can be used for running UI tests in parallel"),
    KnownUIntArguments.priority: ArgumentDescriptionHolder(
        name: "--priority",
        comment: "Job priority. Possible values are in range: [0...999]",
        optional: true),
    KnownUIntArguments.singleTestTimeout: ArgumentDescriptionHolder(
        name: "--single-test-timeout",
        comment: "How long each test may run"),
]

enum KnownStringArguments: ArgumentDescription {
    case additionalApp
    case app
    case analyticsConfiguration
    case destinationConfigurations
    case destinations
    case fbsimctl
    case fbxctest
    case junit
    case output
    case plugin
    case queueServer
    case queueServerDestination
    case queueServerRunConfigurationLocation
    case queueServerTearDownPolicy
    case remoteScheduleStrategy
    case runId
    case runner
    case scheduleStrategy
    case simulatorLocalizationSettings
    case tempFolder
    case testArgFile
    case testDestinations
    case trace
    case watchdogSettings
    case workerId
    case xctestBundle
    
    var name: String {
        return knownStringArguments[self]!.name
    }
    
    var comment: String {
        return knownStringArguments[self]!.comment
    }
    
    var multiple: Bool {
        return knownStringArguments[self]!.multiple
    }
    
    var optional: Bool {
        return knownStringArguments[self]!.optional
    }
}

enum KnownUIntArguments: ArgumentDescription {
    case testRunnerSilenceTimeout
    case numberOfSimulators
    case priority
    case singleTestTimeout
    
    var name: String {
        return knownUIntArguments[self]!.name
    }
    
    var comment: String {
        return knownUIntArguments[self]!.comment
    }
    
    var multiple: Bool {
        return knownUIntArguments[self]!.multiple
    }
    
    var optional: Bool {
        return knownUIntArguments[self]!.optional
    }
}

enum ArgumentsError: Error, CustomStringConvertible {
    case argumentIsMissing(ArgumentDescription)
    case argumentValueCannotBeUsed(ArgumentDescription, Error)
    
    var description: String {
        switch self {
        case .argumentIsMissing(let argument):
            return "Missing argument: \(argument.name). Usage: \(argument.usage)"
        case .argumentValueCannotBeUsed(let argument, let error):
            return "The provided value for argument '\(argument.name)' cannot be used, error: \(error)"
        }
    }
}

extension ArgumentParser {
    func add(stringArgument: KnownStringArguments, file: StaticString = #file, line: Int = #line) -> OptionArgument<String> {
        guard stringArgument.multiple == false else {
            Logger.fatal("Use add(multipleStringArgument:) for \(stringArgument.name) at \(file):\(line)")
        }
        return add(option: stringArgument.name, kind: String.self, usage: stringArgument.usage)
    }
    
    func add(multipleStringArgument: KnownStringArguments, file: StaticString = #file, line: Int = #line) -> OptionArgument<[String]> {
        guard multipleStringArgument.multiple == true else {
            Logger.fatal("Use add(stringArgument:) for \(multipleStringArgument.name) at \(file):\(line)")
        }
        return add(
            option: multipleStringArgument.name,
            kind: [String].self,
            strategy: .oneByOne,
            usage: multipleStringArgument.usage)
    }
    
    func add(intArgument: KnownUIntArguments, file: StaticString = #file, line: Int = #line) -> OptionArgument<UInt> {
        guard intArgument.multiple == false else {
            Logger.fatal("Use add(multipleIntArgument:) for \(intArgument.name) at \(file):\(line)")
        }
        return add(option: intArgument.name, kind: UInt.self, usage: intArgument.usage)
    }
    
    func add(multipleIntArgument: KnownUIntArguments, file: StaticString = #file, line: Int = #line) -> OptionArgument<[UInt]> {
        guard multipleIntArgument.multiple == true else {
            Logger.fatal("Use add(multipleIntArgument:) for \(multipleIntArgument.name) at \(file):\(line)")
        }
        return add(
            option: multipleIntArgument.name,
            kind: [UInt].self,
            strategy: .oneByOne,
            usage: multipleIntArgument.usage)
    }
}


extension UInt: ArgumentKind {
    public init(argument: String) throws {
        guard let uint = UInt(argument) else {
            throw ArgumentConversionError.typeMismatch(value: argument, expectedType: UInt.self)
        }
        
        self = uint
    }
    
    public static let completion: ShellCompletion = .none
}

enum AdditionalArgumentValidationError: Error, CustomStringConvertible {
    case unknownScheduleStrategy(String)
    case notFound(String)
    
    var description: String {
        switch self {
        case .unknownScheduleStrategy(let value):
            return "Unsupported schedule strategy value: \(value). Supported values: \(ScheduleStrategyType.availableRawValues)"
        case .notFound(let path):
            return "File not found: '\(path)'"
        }
    }
}
