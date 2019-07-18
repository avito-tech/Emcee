import Foundation
import Metrics

public final class LaunchMetric: Metric {
    public init(command: String, host: String) {
        let host = host.replacingOccurrences(of: ".", with: "_")
        super.init(
            fixedComponents: [
                "launch"
            ],
            variableComponents: [
                command,
                host,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: 1,
            timestamp: Date()
        )
    }
}
