import Foundation
import Metrics
import Models

public final class EnqueueBucketsMetric: Metric {
    public init(
        numberOfBuckets: Int,
        version: Version,
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfBuckets),
            timestamp: timestamp
        )
    }
}
