import BalancingBucketQueue
import BucketQueue
import Foundation
import Metrics
import Models

public class BucketResultAccepterWithMetricSupport: BucketResultAccepter {
    private let bucketResultAccepter: BucketResultAccepter
    private let jobStateProvider: JobStateProvider
    private let queueStateProvider: RunningQueueStateProvider

    public init(
        bucketResultAccepter: BucketResultAccepter,
        jobStateProvider: JobStateProvider,
        queueStateProvider: RunningQueueStateProvider
    ) {
        self.bucketResultAccepter = bucketResultAccepter
        self.jobStateProvider = jobStateProvider
        self.queueStateProvider = queueStateProvider
    }
    
    public func accept(
        testingResult: TestingResult,
        requestId: RequestId,
        workerId: WorkerId
        ) throws -> BucketQueueAcceptResult
    {
        let acceptResult = try bucketResultAccepter.accept(
            testingResult: testingResult,
            requestId: requestId,
            workerId: workerId
        )
        
        sendMetrics(acceptResult: acceptResult)
        
        return acceptResult
    }
    
    private func sendMetrics(acceptResult: BucketQueueAcceptResult) {
        let jobStates = jobStateProvider.allJobStates
        let runningQueueState = queueStateProvider.runningQueueState
        
        BucketQueueStateLogger(runningQueueState: runningQueueState).logQueueSize()
        
        let queueStateMetrics = QueueStateMetricGatherer.metrics(
            jobStates: jobStates,
            runningQueueState: runningQueueState
        )
        
        let testTimeToStartMetrics: [TimeToStartTestMetric] = acceptResult.testingResultToCollect.unfilteredResults.flatMap { testEntryResult -> [TimeToStartTestMetric] in
            testEntryResult.testRunResults.map { testRunResult in
                let testStartedAt = Date(timeIntervalSince1970: testRunResult.startTime)
                let timeToStart = testStartedAt.timeIntervalSince(acceptResult.dequeuedBucket.enqueuedBucket.enqueueTimestamp)
                return TimeToStartTestMetric(
                    testEntry: testEntryResult.testEntry,
                    timeToStartTest: timeToStart
                )
            }
        }
        MetricRecorder.capture(testTimeToStartMetrics + queueStateMetrics)
    }
}
