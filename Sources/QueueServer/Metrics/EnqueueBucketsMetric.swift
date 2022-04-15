import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class EnqueueBucketsMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(numberOfBuckets),
            timestamp: timestamp
        )
    }
}
