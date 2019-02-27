import Foundation
import Metrics

public final class QueueStateEnqueuedBucketsMetric: Metric {
    public init(
        queueHost: String,
        numberOfEnqueuedBuckets: Int
        )
    {
        super.init(
            fixedComponents: [
                "queue",
                "state",
                "enqueued"
            ],
            variableComponents: [
                queueHost,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfEnqueuedBuckets),
            timestamp: Date()
        )
    }
}
