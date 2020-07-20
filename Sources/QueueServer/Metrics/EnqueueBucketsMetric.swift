import Foundation
import Metrics
import QueueModels

public final class EnqueueBucketsMetric: Metric {
    public init(
        version: Version,
        queueHost: String,
        numberOfBuckets: Int,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "enqueue"
            ],
            variableComponents: [
                version.value,
                queueHost,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfBuckets),
            timestamp: timestamp
        )
    }
}
