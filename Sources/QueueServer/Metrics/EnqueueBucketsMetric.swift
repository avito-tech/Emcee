import Foundation
import Metrics

public final class EnqueueBucketsMetric: Metric {
    public init(numberOfBuckets: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "enqueue"
            ],
            variableComponents: [
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfBuckets),
            timestamp: Date()
        )
    }
}
