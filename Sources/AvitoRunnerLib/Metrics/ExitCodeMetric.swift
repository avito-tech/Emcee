import Foundation
import Metrics

public final class ExitCodeMetric: Metric {
    public init(command: String, host: String, exitCode: Int32) {
        let host = host.replacingOccurrences(of: ".", with: "_")
        super.init(
            fixedComponents: [
                "exitcode"
            ],
            variableComponents: [
                command,
                host,
                "exitcode_\(exitCode)",
                Metric.reservedField,
                Metric.reservedField
            ],
            value: 1.0,
            timestamp: Date()
        )
    }
}
