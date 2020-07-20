import Foundation
import Metrics
import QueueModels

public final class JobStateDequeuedBucketsMetric: Metric {
    public init(
        queueHost: String,
        jobId: String,
        numberOfDequeuedBuckets: Int,
        version: Version,
        timestamp: Date
    ) {
        super.init(
            fixedComponents: [
                "queue",
                "jobs",
                "state",
                "dequeued"
            ],
            variableComponents: [
                queueHost,
                jobId,
                version.value,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfDequeuedBuckets),
            timestamp: timestamp
        )
    }
}
