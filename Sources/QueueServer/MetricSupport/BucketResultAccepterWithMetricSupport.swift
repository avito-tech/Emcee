import BalancingBucketQueue
import BucketQueue
import DateProvider
import Foundation
import LocalHostDeterminer
import EmceeLogging
import Metrics
import MetricsExtensions
import QueueModels

public class BucketResultAccepterWithMetricSupport: BucketResultAccepter {
    private let bucketResultAccepter: BucketResultAccepter
    private let dateProvider: DateProvider
    private let jobStateProvider: JobStateProvider
    private let logger: ContextualLogger
    private let queueStateProvider: RunningQueueStateProvider
    private let version: Version
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider

    public init(
        bucketResultAccepter: BucketResultAccepter,
        dateProvider: DateProvider,
        jobStateProvider: JobStateProvider,
        logger: ContextualLogger,
        queueStateProvider: RunningQueueStateProvider,
        version: Version,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider
    ) {
        self.bucketResultAccepter = bucketResultAccepter
        self.dateProvider = dateProvider
        self.jobStateProvider = jobStateProvider
        self.logger = logger.forType(Self.self)
        self.queueStateProvider = queueStateProvider
        self.version = version
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
    }
    
    public func accept(
        bucketId: BucketId,
        testingResult: TestingResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        let acceptResult = try bucketResultAccepter.accept(
            bucketId: bucketId,
            testingResult: testingResult,
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
        
        do {
            let specificMetricRecorder = try specificMetricRecorderProvider.specificMetricRecorder(
                analyticsConfiguration: acceptResult.dequeuedBucket.enqueuedBucket.bucket.analyticsConfiguration
            )
            specificMetricRecorder.capture(testTimeToStartMetrics + queueStateMetrics)
            if let persistentMetricsJobId = acceptResult.dequeuedBucket.enqueuedBucket.bucket.analyticsConfiguration.persistentMetricsJobId {
                specificMetricRecorder.capture(
                    BucketProcessingDurationMetric(
                        queueHost: LocalHostDeterminer.currentHostAddress,
                        version: version,
                        persistentMetricsJobId: persistentMetricsJobId,
                        duration: dateProvider.currentDate().timeIntervalSince(acceptResult.dequeuedBucket.enqueuedBucket.enqueueTimestamp)
                    )
                )

            }
        } catch {
            logger.error("Failed to send metrics: \(error)")
        }
    }
}
