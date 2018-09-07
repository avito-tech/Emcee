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
    KnownStringArguments.testDestinations: ArgumentDescriptionHolder(
        name: "--test-destinations",
        comment: "A JSON file with test destination configurations. For runtime dump first destination will be used."),
    KnownStringArguments.fbxctest: ArgumentDescriptionHolder(
        name: "--fbxctest",
        comment: "Local path to fbxctest binary, or URL to ZIP archive"),
    KnownStringArguments.xctestBundle: ArgumentDescriptionHolder(
        name: "--xctest-bundle",
        comment: "Path to .xctest bundle with your tests"),
    KnownStringArguments.output: ArgumentDescriptionHolder(
        name: "--output",
        comment: "Path to where should output be stored as JSON file"),
    KnownStringArguments.junit: ArgumentDescriptionHolder(
        name: "--junit",
        comment: "Where the Jnnit report should be created"),
    KnownStringArguments.trace: ArgumentDescriptionHolder(
        name: "--trace",
        comment: "Where the Chrome trace should be created"),
    KnownStringArguments.fbsimctl: ArgumentDescriptionHolder(
        name: "--fbsimctl",
        comment: "Local path to fbsimctl binary, or URL to ZIP archive"),
    KnownStringArguments.app: ArgumentDescriptionHolder(
        name: "--app",
        comment: "Path to your app that will be tested by the UI tests"),
    KnownStringArguments.runner: ArgumentDescriptionHolder(
        name: "--runner",
        comment: "Path to the XCTRunner.app created by Xcode"),
    KnownStringArguments.environment: ArgumentDescriptionHolder(
        name: "--environment",
        comment: "A JSON file with all environment variables that should be applied to the tests",
        optional: true),
    KnownStringArguments.destinations: ArgumentDescriptionHolder(
        name: "--destinations",
        comment: "A JSON file with info about the run destinations for distributed test run"),
    KnownStringArguments.destinationConfigurations: ArgumentDescriptionHolder(
        name: "--destinaton-configurations",
        comment: "A JSON file with additional configuration per destination",
        optional: true),
    KnownStringArguments.onlyTest: ArgumentDescriptionHolder(
        name: "--only-test",
        comment: "List of TestName/testMethod to run.",
        multiple: true,
        optional: true),
    KnownStringArguments.scheduleStrategy: ArgumentDescriptionHolder(
        name: "--schedule-strategy",
        comment: "Defines how to run tests. Can be: \(ScheduleStrategyType.availableRawValues.joined(separator: ", "))"),
    KnownStringArguments.remoteScheduleStrategy: ArgumentDescriptionHolder(
        name: "--remote-schedule-strategy",
        comment: "Defines how to scatter tests to the destination machines. Can be: \(ScheduleStrategyType.availableRawValues.joined(separator: ", "))"),
    KnownStringArguments.simulatorLocalizationSettings: ArgumentDescriptionHolder(
        name: "--simulator-localization-settings",
        comment: "Path to JSON with localization settings",
        optional: true),
    KnownStringArguments.watchdogSettings: ArgumentDescriptionHolder(
        name: "--watchdog-settings",
        comment: "Path to JSON with watchdog settings",
        optional: true),
    KnownStringArguments.tempFolder: ArgumentDescriptionHolder(
        name: "--temp-folder",
        comment: "Where to store temporary stuff, including simulator data"),
    KnownStringArguments.videoPath: ArgumentDescriptionHolder(
        name: "--video-path",
        comment: "Where to store the recorded video of the simulator",
        optional: true),
    KnownStringArguments.oslogPath: ArgumentDescriptionHolder(
        name: "--oslog-path",
        comment: "Where to store the os_log",
        optional: true),
    KnownStringArguments.testLogPath: ArgumentDescriptionHolder(
        name: "--test-log-path",
        comment: "Where to store the test log",
        optional: true),
    KnownStringArguments.additionalApp: ArgumentDescriptionHolder(
        name: "--additional-app",
        comment: "List of absolute paths to additional apps that can be launched diring test run.",
        multiple: true,
        optional: true),
    KnownStringArguments.runId: ArgumentDescriptionHolder(
        name: "--run-id",
        comment: "A logical test run id, usually UUID."),
    KnownStringArguments.queueServer: ArgumentDescriptionHolder(
        name: "--queue-server",
        comment: "An address to a server which runs distRun command, e.g. 127.0.0.1:1234"),
    KnownStringArguments.workerId: ArgumentDescriptionHolder(
        name: "--worker-id",
        comment: "An identifier used to distinguish between workers. Useful to match with deployment destination's identifier"),
]

private let knownUIntArguments: [KnownUIntArguments: ArgumentDescriptionHolder] = [
    KnownUIntArguments.numberOfSimulators: ArgumentDescriptionHolder(
        name: "--number-of-simulators",
        comment: "How many simlutors can be used for running UI tests in parallel"),
    KnownUIntArguments.singleTestTimeout: ArgumentDescriptionHolder(
        name: "--single-test-timeout",
        comment: "How long each test may run"),
    KnownUIntArguments.numberOfRetries: ArgumentDescriptionHolder(
        name: "--number-of-retries",
        comment: "A maximum number of attempts to re-run failed tests"),
    KnownUIntArguments.onlyId: ArgumentDescriptionHolder(
        name: "--only-id",
        comment: "List of test case IDs to run.",
        multiple: true,
        optional: true),
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
]

enum KnownStringArguments: ArgumentDescription {
    case testDestinations
    case fbxctest
    case xctestBundle
    case output
    case junit
    case trace
    case fbsimctl
    case app
    case runner
    case environment
    case destinations
    case destinationConfigurations
    case onlyTest
    case scheduleStrategy
    case remoteScheduleStrategy
    case simulatorLocalizationSettings
    case watchdogSettings
    case tempFolder
    case videoPath
    case oslogPath
    case testLogPath
    case additionalApp
    case runId
    case queueServer
    case workerId
    
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
    case onlyId
    case numberOfSimulators
    case numberOfRetries
    case singleTestTimeout
    case fbxctestSilenceTimeout
    case fbxtestFastTimeout
    case fbxtestRegularTimeout
    case fbxtestSlowTimeout
    case fbxtestBundleReadyTimeout
    case fbxtestCrashCheckTimeout
    
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
            let message = "Use add(multipleStringArgument:) for \(stringArgument.name) at \(file):\(line)"
            log("Error: \(message)", color: .red)
            fatalError(message)
        }
        return add(option: stringArgument.name, kind: String.self, usage: stringArgument.usage)
    }
    
    func add(multipleStringArgument: KnownStringArguments, file: StaticString = #file, line: Int = #line) -> OptionArgument<[String]> {
        guard multipleStringArgument.multiple == true else {
            let message = "Use add(stringArgument:) for \(multipleStringArgument.name) at \(file):\(line)"
            log("Error: \(message)", color: .red)
            fatalError(message)
        }
        return add(
            option: multipleStringArgument.name,
            kind: [String].self,
            strategy: .oneByOne,
            usage: multipleStringArgument.usage)
    }
    
    func add(intArgument: KnownUIntArguments, file: StaticString = #file, line: Int = #line) -> OptionArgument<UInt> {
        guard intArgument.multiple == false else {
            let message = "Use add(multipleIntArgument:) for \(intArgument.name) at \(file):\(line)"
            log("Error: \(message)", color: .red)
            fatalError(message)
        }
        return add(option: intArgument.name, kind: UInt.self, usage: intArgument.usage)
    }
    
    func add(multipleIntArgument: KnownUIntArguments, file: StaticString = #file, line: Int = #line) -> OptionArgument<[UInt]> {
        guard multipleIntArgument.multiple == true else {
            let message = "Use add(multipleIntArgument:) for \(multipleIntArgument.name) at \(file):\(line)"
            log("Error: \(message)", color: .red)
            fatalError(message)
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

enum AdditionalAppValidationError: Error {
    case someAdditionalAppBundlesCannotBeFound
}
