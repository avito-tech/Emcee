import Foundation
import Metrics
import QueueModels

public final class QueueStateEnqueuedTestsMetric: Metric {
    public init(
        queueHost: String,
        numberOfEnqueuedTests: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "enqueued_tests",
            ],
            variableComponents: [
                queueHost,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: Double(numberOfEnqueuedTests),
            timestamp: timestamp
        )
    }
}
