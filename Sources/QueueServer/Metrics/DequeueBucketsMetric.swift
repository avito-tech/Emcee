import Foundation
import Metrics
import Models

public final class DequeueBucketsMetric: Metric {
    public init(
        workerId: WorkerId,
        version: Version,
        numberOfBuckets: Int,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "dequeue"
            ],
            variableComponents: [
                workerId.value,
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
