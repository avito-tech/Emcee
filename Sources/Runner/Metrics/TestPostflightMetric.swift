import Foundation
import Metrics
import QueueModels

public final class TestPostflightMetric: Metric {
    public init(
        host: String,
        duration: Double,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "postflight"],
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
