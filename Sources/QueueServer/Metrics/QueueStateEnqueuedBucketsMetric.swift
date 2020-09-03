import Foundation
import Metrics
import QueueModels

public final class QueueStateEnqueuedBucketsMetric: GraphiteMetric {
    public init(
        queueHost: String,
        numberOfEnqueuedBuckets: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "enqueued"
            ],
            variableComponents: [
                queueHost,
                version.value,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(numberOfEnqueuedBuckets),
            timestamp: timestamp
        )
    }
}
