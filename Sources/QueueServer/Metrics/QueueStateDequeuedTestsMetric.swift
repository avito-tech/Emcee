import Foundation
import Metrics
import QueueModels

public final class QueueStateDequeuedTestsMetric: Metric {
    public init(
        queueHost: String,
        numberOfDequeuedTests: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "dequeued_tests",
            ],
            variableComponents: [
                queueHost,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: Double(numberOfDequeuedTests),
            timestamp: timestamp
        )
    }
}
