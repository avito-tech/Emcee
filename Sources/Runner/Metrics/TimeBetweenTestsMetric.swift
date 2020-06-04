import Foundation
import Metrics

public final class TimeBetweenTestsMetric: Metric {
    public init(
        host: String,
        duration: Double,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "test",
                "between_tests",
                "duration",
            ],
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
