import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class QueueStateDequeuedBucketsMetric: GraphiteMetric {
    public init(
        queueHost: String,
        numberOfDequeuedBuckets: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "dequeued"
            ],
            variableComponents: [
                queueHost,
                version.value,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(numberOfDequeuedBuckets),
            timestamp: timestamp
        )
    }
}
