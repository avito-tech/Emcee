import Foundation
import Metrics
import Models

public final class DequeueBucketsMetric: Metric {
    public init(workerId: WorkerId, numberOfBuckets: Int) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "dequeue"
            ],
            variableComponents: [
                workerId.value,
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
