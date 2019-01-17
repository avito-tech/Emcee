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
    KnownStringArguments.additionalApp: ArgumentDescriptionHolder(
        name: "--additional-app",
        comment: "List of absolute paths to additional apps that can be launched diring test run.",
        multiple: true,
        optional: true),
    KnownStringArguments.app: ArgumentDescriptionHolder(
        name: "--app",
        comment: "Path to your app that will be tested by the UI tests"),
    KnownStringArguments.destinationConfigurations: ArgumentDescriptionHolder(
        name: "--destinaton-configurations",
        comment: "A JSON file with additional configuration per destination",
        optional: true),
    KnownStringArguments.destinations: ArgumentDescriptionHolder(
        name: "--destinations",
        comment: "A JSON file with info about the run destinations for distributed test run"),
    KnownStringArguments.environment: ArgumentDescriptionHolder(
        name: "--environment",
        comment: "A JSON file with all environment variables that should be applied to the tests",
        optional: true),
    KnownStringArguments.fbsimctl: ArgumentDescriptionHolder(
        name: "--fbsimctl",
        comment: "Local path to fbsimctl binary, or URL to ZIP archive"),
    KnownStringArguments.fbxctest: ArgumentDescriptionHolder(
        name: "--fbxctest",
        comment: "Local path to fbxctest binary, or URL to ZIP archive"),
    KnownStringArguments.junit: ArgumentDescriptionHolder(
        name: "--junit",
        comment: "Where the combined (the one for all test destinations) Junit report should be created"),
    KnownStringArguments.onlyTest: ArgumentDescriptionHolder(
        name: "--only-test",
        comment: "List of TestName/testMethod to run.",
        multiple: true,
        optional: true),
    KnownStringArguments.output: ArgumentDescriptionHolder(
        name: "--output",
        comment: "Path to where should output be stored as JSON file"),
    KnownStringArguments.plugin: ArgumentDescriptionHolder(
        name: "--plugin",
        comment: ".emceeplugin bundle local path (or URL to ZIP). Plugin bundle should contain an executable: MyPlugin.emceeplugin/Plugin",
        multiple: true,
        optional: true),
    KnownStringArguments.queueServer: ArgumentDescriptionHolder(
        name: "--queue-server",
        comment: "An address to a server which runs distRun command, e.g. 127.0.0.1:1234"),
    KnownStringArguments.remoteScheduleStrategy: ArgumentDescriptionHolder(
        name: "--remote-schedule-strategy",
        comment: "Defines how to scatter tests to the destination machines. Can be: \(ScheduleStrategyType.availableRawValues.joined(separator: ", "))"),
    KnownStringArguments.runId: ArgumentDescriptionHolder(
        name: "--run-id",
        comment: "A logical test run id, usually a random string, e.g. UUID."),
    KnownStringArguments.runner: ArgumentDescriptionHolder(
        name: "--runner",
        comment: "Path to the XCTRunner.app created by Xcode"),
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
        comment: "A description of all tests that expected to be ran. More flexible alternative to combination of --only-test/--only-id + --test-destinations arguments.",
        optional: true),
    KnownStringArguments.testDestinations: ArgumentDescriptionHolder(
        name: "--test-destinations",
        comment: "A JSON file with test destination configurations. For runtime dump only first destination will be used."),
    KnownStringArguments.trace: ArgumentDescriptionHolder(
        name: "--trace",
        comment: "Where the combined (the one for all test destinations) Chrome trace should be created"),
    KnownStringArguments.watchdogSettings: ArgumentDescriptionHolder(
        name: "--watchdog-settings",
        comment: "Location of JSON file with watchdog settings",
        optional: true),
    KnownStringArguments.workerId: ArgumentDescriptionHolder(
        name: "--worker-id",
        comment: "An identifier used to distinguish between workers. Useful to match with deployment destination's identifier"),
    KnownStringArguments.xctestBundle: ArgumentDescriptionHolder(
        name: "--xctest-bundle",
        comment: "Path to .xctest bundle with your tests"),
]

private let knownUIntArguments: [KnownUIntArguments: ArgumentDescriptionHolder] = [
    KnownUIntArguments.fbxctestSilenceTimeout: ArgumentDescriptionHolder(
        name: "--fbxctest-silence-timeout",
        comment: "A maximum allowed duration for a fbxctest stdout/stderr to be silent",
        optional: true),
    KnownUIntArguments.fbxtestFastTimeout: ArgumentDescriptionHolder(
        name: "--fbxctest-fast-timeout",
        comment: "Overrides fbxtest's internal FastTimeout",
        optional: true),
    KnownUIntArguments.fbxtestRegularTimeout: ArgumentDescriptionHolder(
        name: "--fbxctest-regular-timeout",
        comment: "Overrides fbxtest's internal RegularTimeout",
        optional: true),
    KnownUIntArguments.fbxtestSlowTimeout: ArgumentDescriptionHolder(
        name: "--fbxctest-slow-timeout",
        comment: "Overrides fbxtest's internal SlowTimeout",
        optional: true),
    KnownUIntArguments.fbxtestBundleReadyTimeout: ArgumentDescriptionHolder(
        name: "--fbxctest-bundle-ready-timeout",
        comment: "Overrides fbxtest's internal BundleReady Timeout",
        optional: true),
    KnownUIntArguments.fbxtestCrashCheckTimeout: ArgumentDescriptionHolder(
        name: "--fbxctest-crash-check-timeout",
        comment: "Overrides fbxtest's internal CrashCheck Timeout",
        optional: true),
    KnownUIntArguments.numberOfRetries: ArgumentDescriptionHolder(
        name: "--number-of-retries",
        comment: "A maximum number of attempts to re-run failed tests"),
    KnownUIntArguments.numberOfSimulators: ArgumentDescriptionHolder(
        name: "--number-of-simulators",
        comment: "How many simlutors can be used for running UI tests in parallel"),
    KnownUIntArguments.onlyId: ArgumentDescriptionHolder(
        name: "--only-id",
        comment: "List of test case IDs to run.",
        multiple: true,
        optional: true),
    KnownUIntArguments.singleTestTimeout: ArgumentDescriptionHolder(
        name: "--single-test-timeout",
        comment: "How long each test may run"),
]

enum KnownStringArguments: ArgumentDescription {
    case additionalApp
    case app
    case destinationConfigurations
    case destinations
    case environment
    case fbsimctl
    case fbxctest
    case junit
    case onlyTest
    case output
    case plugin
    case queueServer
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
    case fbxctestSilenceTimeout
    case fbxtestBundleReadyTimeout
    case fbxtestCrashCheckTimeout
    case fbxtestFastTimeout
    case fbxtestRegularTimeout
    case fbxtestSlowTimeout
    case numberOfRetries
    case numberOfSimulators
    case onlyId
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
    case someAdditionalAppBundlesCannotBeFound
    case incorrectQueueServerFormat(String)
    
    var description: String {
        switch self {
        case .unknownScheduleStrategy(let value):
            return "Unsupported schedule strategy value: \(value). Supported values: \(ScheduleStrategyType.availableRawValues)"
        case .notFound(let path):
            return "File not found: '\(path)'"
        case .someAdditionalAppBundlesCannotBeFound:
            return "Additional app bundle path(s) cannot be found"
        case .incorrectQueueServerFormat(let actual):
            return "Queue server address has unexpected format. Expected to be: 'example.com:1234' or '127.0.0.1:1234', found: \(actual)"
        }
    }
}
