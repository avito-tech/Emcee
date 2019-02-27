import BalancingBucketQueue
import BucketQueue
import EventBus
import Foundation
import Metrics
import Models

public class BucketResultAccepterWithMetricSupport: BucketResultAccepter {
    private let bucketResultAccepter: BucketResultAccepter
    private let eventBus: EventBus
    private let jobStateProvider: JobStateProvider
    private let queueStateProvider: QueueStateProvider

    public init(
        bucketResultAccepter: BucketResultAccepter,
        eventBus: EventBus,
        jobStateProvider: JobStateProvider,
        queueStateProvider: QueueStateProvider
        )
    {
        self.bucketResultAccepter = bucketResultAccepter
        self.eventBus = eventBus
        self.jobStateProvider = jobStateProvider
        self.queueStateProvider = queueStateProvider
    }
    
    public func accept(
        testingResult: TestingResult,
        requestId: String,
        workerId: String
        )
        throws -> BucketQueueAcceptResult
    {
        let acceptResult = try bucketResultAccepter.accept(
            testingResult: testingResult,
            requestId: requestId,
            workerId: workerId
        )
        
        eventBus.post(event: .didObtainTestingResult(acceptResult.testingResultToCollect))
        sendMetrics(acceptResult: acceptResult)
        
        return acceptResult
    }
    
    private func sendMetrics(acceptResult: BucketQueueAcceptResult) {
        let jobStates = jobStateProvider.allJobStates
        let queueState = queueStateProvider.state
        
        BucketQueueStateLogger(state: queueState).logQueueSize()
        
        let queueStateMetrics = QueueStateMetricGatherer.metrics(
            jobStates: jobStates,
            queueState: queueState
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
