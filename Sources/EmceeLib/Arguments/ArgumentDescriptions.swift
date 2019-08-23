import ArgLib
import Foundation
import Models

final class ArgumentDescriptions {
    static let analyticsConfiguration = doubleDashedDescription(dashlessName: "analytics-configuration", overview: "Location of analytics configuration JSON file to support various analytic destinations")
    static let queueServer = doubleDashedDescription(dashlessName: "queue-server", overview: "An address to a server which runs job queues, e.g. 127.0.0.1:1234")
    static let queueServerRunConfigurationLocation = doubleDashedDescription(dashlessName: "queue-server-run-configuration-location", overview: "JSON file location which describes QueueServerRunConfiguration. Either /path/to/file.json, or http://example.com/file.zip#path/to/config.json")
    static let workerId = doubleDashedDescription(dashlessName: "worker-id", overview: "An identifier used to distinguish between workers. Useful to match with deployment destination's identifier")

    private static func doubleDashedDescription(dashlessName: String, overview: String) -> ArgumentDescription {
        return ArgumentDescription(name: .doubleDashed(dashlessName: dashlessName), overview: overview)
    }
}
