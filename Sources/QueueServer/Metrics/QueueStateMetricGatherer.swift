import DateProvider
import Foundation
import LocalHostDeterminer
import Metrics
import Models
import QueueModels

public final class QueueStateMetricGatherer {
    private let dateProvider: DateProvider
    private let version: Version
    
    public init(
        dateProvider: DateProvider,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.version = version
    }
    
    public func metrics(
        jobStates: [JobState],
        runningQueueState: RunningQueueState
    ) -> [Metric] {
        let queueHost = LocalHostDeterminer.currentHostAddress
        let queueMetrics = [
            QueueStateEnqueuedBucketsMetric(
                queueHost: queueHost,
                numberOfEnqueuedBuckets: runningQueueState.enqueuedTests.count,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            QueueStateDequeuedBucketsMetric(
                queueHost: queueHost,
                numberOfDequeuedBuckets: runningQueueState.dequeuedTests.count,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            JobCountMetric(
                queueHost: queueHost,
                version: version,
                jobCount: jobStates.count,
                timestamp: dateProvider.currentDate()
            )
        ]
        let jobMetrics = jobStates.flatMap { jobState -> [Metric] in
            [
                JobStateEnqueuedBucketsMetric(
                    queueHost: queueHost,
                    jobId: jobState.jobId.value,
                    numberOfEnqueuedBuckets: runningQueueState.enqueuedTests.count,
                    version: version,
                    timestamp: dateProvider.currentDate()
                ),
                JobStateDequeuedBucketsMetric(
                    queueHost: queueHost,
                    jobId: jobState.jobId.value,
                    numberOfDequeuedBuckets: runningQueueState.dequeuedTests.count,
                    version: version,
                    timestamp: dateProvider.currentDate()
                )
            ]
        }
        return queueMetrics + jobMetrics
    }
}
