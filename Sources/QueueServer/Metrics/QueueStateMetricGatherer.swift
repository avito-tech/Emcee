import Foundation
import Metrics
import Models
import LocalHostDeterminer

public final class QueueStateMetricGatherer {
    private init() {}
    
    public static func metrics(jobStates: [JobState], queueState: QueueState) -> [Metric] {
        let queueHost = LocalHostDeterminer.currentHostAddress
        let queueMetrics = [
            QueueStateEnqueuedBucketsMetric(
                queueHost: queueHost,
                numberOfEnqueuedBuckets: queueState.enqueuedBucketCount
            ),
            QueueStateDequeuedBucketsMetric(
                queueHost: queueHost,
                numberOfDequeuedBuckets: queueState.dequeuedBucketCount
            ),
            JobCountMetric(queueHost: queueHost, jobCount: jobStates.count)
        ]
        let jobMetrics = jobStates.flatMap { jobState -> [Metric] in
            [
                JobStateEnqueuedBucketsMetric(
                    queueHost: queueHost,
                    jobId: jobState.jobId.value,
                    numberOfEnqueuedBuckets: jobState.queueState.enqueuedBucketCount
                ),
                JobStateDequeuedBucketsMetric(
                    queueHost: queueHost,
                    jobId: jobState.jobId.value,
                    numberOfDequeuedBuckets: jobState.queueState.dequeuedBucketCount
                )
            ]
        }
        return queueMetrics + jobMetrics
    }
}
