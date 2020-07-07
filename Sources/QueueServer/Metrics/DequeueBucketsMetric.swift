import Foundation
import Metrics
import Models

public final class DequeueBucketsMetric: Metric {
    public init(
        workerId: WorkerId,
        version: Version,
        queueHost: String,
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
                queueHost,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfBuckets),
            timestamp: timestamp
        )
    }
}
