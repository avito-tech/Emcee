import Foundation
import Metrics

public final class JobStateDequeuedBucketsMetric: Metric {
    public init(
        queueHost: String,
        jobId: String,
        numberOfDequeuedBuckets: Int
        )
    {
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
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField,
                Metric.reservedField
            ],
            value: Double(numberOfDequeuedBuckets),
            timestamp: Date()
        )
    }
}
