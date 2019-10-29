import ArgLib
import Foundation
import Models

final class ArgumentDescriptions {
    static let junit = doubleDashedDescription(dashlessName: "junit", overview: "Path where the combined (for all test destinations) Junit report file should be created")
    static let output = doubleDashedDescription(dashlessName: "output", overview: "Path to file where to store the output")
    static let plugin = doubleDashedDescription(dashlessName: "plugin", overview: "URL to ZIP file with .emceeplugin bundle. Plugin bundle should contain an executable: MyPlugin.emceeplugin/Plugin", multiple: true)
    static let priority = doubleDashedDescription(dashlessName: "priority", overview: "Job priority. Possible values are in range: [0...999]")
    static let queueServer = doubleDashedDescription(dashlessName: "queue-server", overview: "An address to a server which runs job queues, e.g. 127.0.0.1:1234")
    static let queueServerDestination = doubleDashedDescription(dashlessName: "queue-server-destination", overview: "A JSON file with info about deployment destination which will be used to start remote queue server")
    static let queueServerRunConfigurationLocation = doubleDashedDescription(dashlessName: "queue-server-run-configuration-location", overview: "JSON file location which describes QueueServerRunConfiguration. Either /path/to/file.json, or http://example.com/file.zip#path/to/config.json")
    static let runId = doubleDashedDescription(dashlessName: "run-id", overview: "Unique logical test run id, usually a random string, e.g. UUID")
    static let tempFolder = doubleDashedDescription(dashlessName: "temp-folder", overview: "Where to store temporary stuff, including simulator data")
    static let testArgFile = doubleDashedDescription(dashlessName: "test-arg-file", overview: "JSON file with test plan")
    static let trace = doubleDashedDescription(dashlessName: "trace", overview: "Path where the combined (for all test destinations) Chrome trace file should be created")
    static let workerId = doubleDashedDescription(dashlessName: "worker-id", overview: "An identifier used to distinguish between workers. Useful to match with deployment destination's identifier")
    
    private static func doubleDashedDescription(dashlessName: String, overview: String, multiple: Bool = false) -> ArgumentDescription {
        return ArgumentDescription(name: .doubleDashed(dashlessName: dashlessName), overview: overview, multiple: multiple)
    }
}
