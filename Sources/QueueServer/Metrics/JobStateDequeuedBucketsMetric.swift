import Foundation
import Graphite
import MetricsRecording
import QueueModels

public final class JobStateDequeuedBucketsMetric: GraphiteMetric {
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
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField,
                GraphiteMetric.reservedField
            ],
            value: Double(numberOfDequeuedBuckets),
            timestamp: timestamp
        )
    }
}
