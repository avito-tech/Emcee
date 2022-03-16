import DateProvider
import Foundation
import Graphite
import Metrics
import QueueModels

public final class QueueStateMetricGatherer {
    private let dateProvider: DateProvider
    private let queueHost: String
    private let version: Version
    
    public init(
        dateProvider: DateProvider,
        queueHost: String,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.queueHost = queueHost
        self.version = version
    }
    
    public func metrics(
        jobStates: [JobState],
        runningQueueState: RunningQueueState
    ) -> [GraphiteMetric] {
        let queueMetrics = [
            QueueStateDequeuedBucketsMetric(
                queueHost: queueHost,
                numberOfDequeuedBuckets: runningQueueState.dequeuedBucketCount,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            QueueStateDequeuedTestsMetric(
                queueHost: queueHost,
                numberOfDequeuedTests: runningQueueState.dequeuedTests.flattenValues.count,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            QueueStateEnqueuedBucketsMetric(
                queueHost: queueHost,
                numberOfEnqueuedBuckets: runningQueueState.enqueuedBucketCount,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            QueueStateEnqueuedTestsMetric(
                queueHost: queueHost,
                numberOfEnqueuedTests: runningQueueState.enqueuedTests.count,
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
        let jobMetrics = jobStates.flatMap { jobState -> [GraphiteMetric] in
            switch jobState.queueState {
            case .deleted:
                return []
            case .running(let jobQueueState):
                return [
                    JobStateEnqueuedBucketsMetric(
                        queueHost: queueHost,
                        jobId: jobState.jobId.value,
                        numberOfEnqueuedBuckets: jobQueueState.enqueuedBucketCount,
                        version: version,
                        timestamp: dateProvider.currentDate()
                    ),
                    JobStateDequeuedBucketsMetric(
                        queueHost: queueHost,
                        jobId: jobState.jobId.value,
                        numberOfDequeuedBuckets: jobQueueState.dequeuedBucketCount,
                        version: version,
                        timestamp: dateProvider.currentDate()
                    )
                ]
            }
        }
        return queueMetrics + jobMetrics
    }
}
