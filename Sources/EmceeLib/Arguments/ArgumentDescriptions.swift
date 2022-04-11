import ArgLib
import Foundation

final class ArgumentDescriptions {
    static let emceeVersion = doubleDashedDescription(dashlessName: "emcee-version", overview: "Explicit version of Emcee binary")
    static let junit = doubleDashedDescription(dashlessName: "junit", overview: "Path where the combined (for all test destinations) Junit report file should be created")
    static let output = doubleDashedDescription(dashlessName: "output", overview: "Path to file where to store the output")
    static let queueServer = doubleDashedDescription(dashlessName: "queue-server", overview: "An address to a server which runs job queues, e.g. 127.0.0.1:1234")
    static let queueServerConfigurationLocation = doubleDashedDescription(dashlessName: "queue-server-configuration-location", overview: "JSON file location which describes QueueServerConfiguration, local path or URL. See: https://github.com/avito-tech/Emcee/wiki/URL-Handling")
    static let remoteCacheConfig = doubleDashedDescription(dashlessName: "remote-cache-config", overview: "JSON file with remote server settings")
    static let setFeatureStatus = doubleDashedDescription(dashlessName: "set-feature-status", overview: "Enabled/Disabled")
    static let tempFolder = doubleDashedDescription(dashlessName: "temp-folder", overview: "Where to store temporary stuff, including simulator data")
    static let testArgFile = doubleDashedDescription(dashlessName: "test-arg-file", overview: "JSON file with test plan. See: https://github.com/avito-tech/Emcee/wiki/Test-Arg-File")
    static let trace = doubleDashedDescription(dashlessName: "trace", overview: "Path where the combined (for all test destinations) Chrome trace file should be created")
    static let workerId = doubleDashedDescription(dashlessName: "worker-id", overview: "An identifier used to distinguish between workers. Useful to match with deployment destination's identifier")
    static let hostname = doubleDashedDescription(dashlessName: "hostname", overview: "Hostname which should be used by Emcee")
    
    static let worker = doubleDashedDescription(dashlessName: "worker", overview: "URL which describes a worker to spawn")
    static let queue = doubleDashedDescription(dashlessName: "queue", overview: "URL which describes a queue to spawn")
    
    static let testBundle = doubleDashedDescription(dashlessName: "test-bundle", overview: "Path to an .xctest bundle")
    static let app = doubleDashedDescription(dashlessName: "app", overview: "Path to an .app bundle")
    static let runner = doubleDashedDescription(dashlessName: "runner", overview: "Path to an XX-Runner.app")
    
    static let test = doubleDashedDescription(dashlessName: "test", overview: "Test to execute, e.g. ClassName/testMethod")
    static let retries = doubleDashedDescription(dashlessName: "retries", overview: "How many retries to attempt")
    static let testTimeout = doubleDashedDescription(dashlessName: "test-timeout", overview: "Maximum test execution duration")
    static let device = doubleDashedDescription(dashlessName: "device", overview: "Device to run test on, e.g. 'iPhone X'")
    static let kind = doubleDashedDescription(dashlessName: "kind", overview: "Runtime kind, e.g. 'iOS' or 'tvOS'")
    static let runtime = doubleDashedDescription(dashlessName: "runtime", overview: "Runtime to run test on, e.g. '15.0'")
    
    static let locale = doubleDashedDescription(dashlessName: "locale", overview: "Simulator locale, e.g. 'en_US', 'ru_RU'")
    static let language = doubleDashedDescription(dashlessName: "language", overview: "Simulator language, e.g. 'en', 'ru-US'")
    static let keyboard = doubleDashedDescription(dashlessName: "keyboard", overview: "Simulator keyboard, e.g. 'en_US@sw=QWERTY;hw=Automatic', 'ru_RU@sw=Russian;hw=Automatic'")
    static let passcodeKeyboard = doubleDashedDescription(dashlessName: "passcode-keyboard", overview: "Simulator passcode keyboard, e.g. 'ru_RU@sw=Russian;hw=Automatic', 'en_US@sw=QWERTY;hw=Automatic'")

    private static func doubleDashedDescription(dashlessName: String, overview: String, multiple: Bool = false) -> ArgumentDescription {
        return ArgumentDescription(name: .doubleDashed(dashlessName: dashlessName), overview: overview, multiple: multiple)
    }
}
