import Foundation
import Metrics

public final class TestPreflightMetric: Metric {
    public init(
        host: String,
        duration: Double,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "preflight"],
            variableComponents: [
                host,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: duration,
            timestamp: timestamp
        )
    }
}
