import Foundation
import Metrics
import Models

public final class JobStateEnqueuedBucketsMetric: Metric {
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfEnqueuedBuckets),
            timestamp: timestamp
        )
    }
}
