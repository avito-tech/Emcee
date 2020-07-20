import Foundation
import Metrics
import QueueModels

public final class QueueStateDequeuedBucketsMetric: Metric {
    public init(
        queueHost: String,
        numberOfDequeuedBuckets: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "dequeued"
            ],
            variableComponents: [
                queueHost,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfDequeuedBuckets),
            timestamp: timestamp
        )
    }
}
