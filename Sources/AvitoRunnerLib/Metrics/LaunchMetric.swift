import Foundation
import Metrics

public final class LaunchMetric: Metric {
    public init(command: String, host: String) {
        let host = host.replacingOccurrences(of: ".", with: "_")
        super.init(
            fixedComponents: ["launch"],
            variableComponents: [command, host, "reserved", "reserved"],
            value: 1,
            timestamp: Date()
        )
    }
}
