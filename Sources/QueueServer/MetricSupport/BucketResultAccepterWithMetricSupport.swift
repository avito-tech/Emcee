import BalancingBucketQueue
import BucketQueue
import DateProvider
import Foundation
import LocalHostDeterminer
import Metrics
import QueueModels

public class BucketResultAccepterWithMetricSupport: BucketResultAccepter {
    private let bucketResultAccepter: BucketResultAccepter
    private let dateProvider: DateProvider
    private let jobStateProvider: JobStateProvider
    private let queueStateProvider: RunningQueueStateProvider
    private let version: Version

    public init(
        bucketResultAccepter: BucketResultAccepter,
        dateProvider: DateProvider,
        jobStateProvider: JobStateProvider,
        queueStateProvider: RunningQueueStateProvider,
        version: Version
    ) {
        self.bucketResultAccepter = bucketResultAccepter
        self.dateProvider = dateProvider
        self.jobStateProvider = jobStateProvider
        self.queueStateProvider = queueStateProvider
        self.version = version
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
        let queueStateMetricGatherer = QueueStateMetricGatherer(
            dateProvider: dateProvider,
            version: version
        )
        
        let queueStateMetrics = queueStateMetricGatherer.metrics(
            jobStates: jobStates,
            runningQueueState: runningQueueState
        )
        
        let testTimeToStartMetrics: [TimeToStartTestMetric] = acceptResult.testingResultToCollect.unfilteredResults.flatMap { testEntryResult -> [TimeToStartTestMetric] in
            testEntryResult.testRunResults.map { testRunResult in
                let testStartedAt = Date(timeIntervalSince1970: testRunResult.startTime)
                let timeToStart = testStartedAt.timeIntervalSince(acceptResult.dequeuedBucket.enqueuedBucket.enqueueTimestamp)
                return TimeToStartTestMetric(
                    testEntry: testEntryResult.testEntry,
                    version: version,
                    queueHost: LocalHostDeterminer.currentHostAddress,
                    timeToStartTest: timeToStart,
                    timestamp: dateProvider.currentDate()
                )
            }
        }
        MetricRecorder.capture(testTimeToStartMetrics + queueStateMetrics)
    }
}
