import Foundation
import Metrics

public final class JobStateEnqueuedBucketsMetric: Metric {
    public init(
        queueHost: String,
        jobId: String,
        numberOfEnqueuedBuckets: Int
        )
    {
        super.init(
            fixedComponents: [
                "queue",
                "jobs",
                "state",
                "enqueued"
            ],
            variableComponents: [
                queueHost,
                jobId,
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
