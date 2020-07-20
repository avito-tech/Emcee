import Foundation
import Metrics
import QueueModels

public final class TimeToDequeueBucketMetric: Metric {
    public init(
        version: Version,
        queueHost: String,
        timeInterval: TimeInterval,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "buckets",
                "time_to_dequeue"
            ],
            variableComponents: [
                version.value,
                queueHost,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: timeInterval,
            timestamp: timestamp
        )
    }
}
