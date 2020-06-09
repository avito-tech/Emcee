import Foundation
import Metrics

public final class TestPostflightMetric: Metric {
    public init(
        host: String,
        duration: Double,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "postflight"],
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
