import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class DequeueBucketsMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(numberOfBuckets),
            timestamp: timestamp
        )
    }
}
