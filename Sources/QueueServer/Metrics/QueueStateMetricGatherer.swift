import Foundation
import Metrics
import Models
import LocalHostDeterminer

public final class QueueStateMetricGatherer {
    private init() {}
    
    public static func metrics(jobStates: [JobState], runningQueueState: RunningQueueState) -> [Metric] {
        let queueHost = LocalHostDeterminer.currentHostAddress
        let queueMetrics = [
            QueueStateEnqueuedBucketsMetric(
                queueHost: queueHost,
                numberOfEnqueuedBuckets: runningQueueState.enqueuedBucketCount
            ),
            QueueStateDequeuedBucketsMetric(
                queueHost: queueHost,
                numberOfDequeuedBuckets: runningQueueState.dequeuedBucketCount
            ),
            JobCountMetric(queueHost: queueHost, jobCount: jobStates.count)
        ]
        let jobMetrics = jobStates.flatMap { jobState -> [Metric] in
            [
                JobStateEnqueuedBucketsMetric(
                    queueHost: queueHost,
                    jobId: jobState.jobId.value,
                    numberOfEnqueuedBuckets: runningQueueState.enqueuedBucketCount
                ),
                JobStateDequeuedBucketsMetric(
                    queueHost: queueHost,
                    jobId: jobState.jobId.value,
                    numberOfDequeuedBuckets: runningQueueState.dequeuedBucketCount
                )
            ]
        }
        return queueMetrics + jobMetrics
    }
}
