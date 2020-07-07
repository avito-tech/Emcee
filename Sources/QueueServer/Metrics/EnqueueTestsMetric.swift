import Foundation
import Metrics
import Models

/// Indicates an event when you enqueue some tests
public final class EnqueueTestsMetric: Metric {
    public init(
        version: Version,
        queueHost: String,
        numberOfTests: Int,
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
                queueHost,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfTests),
            timestamp: timestamp
        )
    }
}
