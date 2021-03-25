import BalancingBucketQueue
import DateProvider
import Foundation
import LocalHostDeterminer
import EmceeLogging
import Metrics
import MetricsExtensions
import QueueModels
import ScheduleStrategy

public final class TestsEnqueuer {
    private let bucketSplitInfo: BucketSplitInfo
    private let dateProvider: DateProvider
    private let enqueueableBucketReceptor: EnqueueableBucketReceptor
    private let logger: ContextualLogger
    private let version: Version
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider

    public init(
        bucketSplitInfo: BucketSplitInfo,
        dateProvider: DateProvider,
        enqueueableBucketReceptor: EnqueueableBucketReceptor,
        logger: ContextualLogger,
        version: Version,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider
    ) {
        self.bucketSplitInfo = bucketSplitInfo
        self.dateProvider = dateProvider
        self.enqueueableBucketReceptor = enqueueableBucketReceptor
        self.logger = logger
        self.version = version
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
    }
    
    public func enqueue(
        bucketSplitter: BucketSplitter,
        testEntryConfigurations: [TestEntryConfiguration],
        prioritizedJob: PrioritizedJob
    ) throws {
        let buckets = bucketSplitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: bucketSplitInfo
        )
        try enqueueableBucketReceptor.enqueue(buckets: buckets, prioritizedJob: prioritizedJob)
        
        try specificMetricRecorderProvider.specificMetricRecorder(
            analyticsConfiguration: prioritizedJob.analyticsConfiguration
        ).capture(
            EnqueueTestsMetric(
                version: version,
                queueHost: LocalHostDeterminer.currentHostAddress,
                numberOfTests: testEntryConfigurations.count,
                timestamp: dateProvider.currentDate()
            ),
            EnqueueBucketsMetric(
                version: version,
                queueHost: LocalHostDeterminer.currentHostAddress,
                numberOfBuckets: buckets.count,
                timestamp: dateProvider.currentDate()
            )
        )
        
        logger.info("Enqueued \(buckets.count) buckets for job '\(prioritizedJob)'")
        for bucket in buckets {
            logger.debug("-- \(bucket) with tests:")
            for testEntries in bucket.testEntries {
                logger.debug("-- -- \(testEntries)")
            }
        }
    }
}
