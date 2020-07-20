import Foundation
import Metrics
import QueueModels

public final class TimeBetweenTestsMetric: Metric {
    public init(
        host: String,
        duration: Double,
        version: Version,
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
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: duration,
            timestamp: timestamp
        )
    }
}
