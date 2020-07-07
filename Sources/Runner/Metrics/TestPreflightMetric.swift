import Foundation
import Metrics
import Models

public final class TestPreflightMetric: Metric {
    public init(
        host: String,
        duration: Double,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: ["test", "preflight"],
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
