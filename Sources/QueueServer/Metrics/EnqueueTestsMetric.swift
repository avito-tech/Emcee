import Foundation
import Metrics
import Models

/// Indicates an event when you enqueue some tests
public final class EnqueueTestsMetric: Metric {
    public init(
        numberOfTests: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "tests",
                "enqueue"
            ],
            variableComponents: [
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: timestamp
        )
    }
}
