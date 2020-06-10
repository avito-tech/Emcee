import Foundation
import LocalHostDeterminer
import Metrics
import Models
import QueueModels

public final class QueueStateMetricGatherer {
    private init() {}
    
    public static func metrics(jobStates: [JobState], runningQueueState: RunningQueueState) -> [Metric] {
        let queueHost = LocalHostDeterminer.currentHostAddress
        let queueMetrics = [
            QueueStateEnqueuedBucketsMetric(
                queueHost: queueHost,
                numberOfEnqueuedBuckets: runningQueueState.enqueuedTests.count
            ),
            QueueStateDequeuedBucketsMetric(
                queueHost: queueHost,
                numberOfDequeuedBuckets: runningQueueState.dequeuedTests.count
            ),
            JobCountMetric(queueHost: queueHost, jobCount: jobStates.count)
        ]
        let jobMetrics = jobStates.flatMap { jobState -> [Metric] in
            [
                JobStateEnqueuedBucketsMetric(
                    queueHost: queueHost,
                    jobId: jobState.jobId.value,
                    numberOfEnqueuedBuckets: runningQueueState.enqueuedTests.count
                ),
                JobStateDequeuedBucketsMetric(
                    queueHost: queueHost,
                    jobId: jobState.jobId.value,
                    numberOfDequeuedBuckets: runningQueueState.dequeuedTests.count
                )
            ]
        }
        return queueMetrics + jobMetrics
    }
}
