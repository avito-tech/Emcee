import ArgLib
import Foundation
import Models

final class ArgumentDescriptions {
    static let analyticsConfiguration = doubleDashedDescription(dashlessName: "analytics-configuration", overview: "Location of analytics configuration JSON file to support various analytic destinations")
    static let app = doubleDashedDescription(dashlessName: "app", overview: "Location of app bundle that will be tested by the tests. Required for application and UI tests.")
    static let fbsimctl = doubleDashedDescription(dashlessName: "fbsimctl", overview: "Location of fbsimctl tool, URL to ZIP file or path to executable")
    static let fbxctest = doubleDashedDescription(dashlessName: "fbxctest", overview: "Location of fbxctest tool, URL to ZIP file or path to executable")
    static let output = doubleDashedDescription(dashlessName: "output", overview: "Path to file where to store the output")
    static let queueServer = doubleDashedDescription(dashlessName: "queue-server", overview: "An address to a server which runs job queues, e.g. 127.0.0.1:1234")
    static let queueServerRunConfigurationLocation = doubleDashedDescription(dashlessName: "queue-server-run-configuration-location", overview: "JSON file location which describes QueueServerRunConfiguration. Either /path/to/file.json, or http://example.com/file.zip#path/to/config.json")
    static let tempFolder = doubleDashedDescription(dashlessName: "temp-folder", overview: "Where to store temporary stuff, including simulator data")
    static let testDestinations = doubleDashedDescription(dashlessName: "test-destinations", overview: "A JSON file with test destination configurations. For runtime dump only the first destination will be used.")
    static let workerId = doubleDashedDescription(dashlessName: "worker-id", overview: "An identifier used to distinguish between workers. Useful to match with deployment destination's identifier")
    static let xctestBundle = doubleDashedDescription(dashlessName: "xctest-bundle", overview: "Location of .xctest bundle, URL to ZIP file or path to bundle")
    
    private static func doubleDashedDescription(dashlessName: String, overview: String) -> ArgumentDescription {
        return ArgumentDescription(name: .doubleDashed(dashlessName: dashlessName), overview: overview)
    }
}
