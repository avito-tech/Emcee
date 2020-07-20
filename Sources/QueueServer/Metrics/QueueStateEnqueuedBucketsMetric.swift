import Foundation
import Metrics
import QueueModels

public final class QueueStateEnqueuedBucketsMetric: Metric {
    public init(
        queueHost: String,
        numberOfEnqueuedBuckets: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "enqueued"
            ],
            variableComponents: [
                queueHost,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfEnqueuedBuckets),
            timestamp: timestamp
        )
    }
}
