import Foundation
import Metrics
import QueueModels

public final class JobStateEnqueuedBucketsMetric: GraphiteMetric {
    public init(
        queueHost: String,
        jobId: String,
        numberOfEnqueuedBuckets: Int,
        version: Version,
        timestamp: Date
    ) {
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
