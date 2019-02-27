import Foundation
import Metrics

public final class DequeueBucketsMetric: Metric {
    public init(workerId: String, numberOfBuckets: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "dequeue"
            ],
            variableComponents: [
                workerId,
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
