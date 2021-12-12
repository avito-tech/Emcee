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
    private let bucketGenerator: BucketGenerator
    private let bucketSplitInfo: BucketSplitInfo
    private let dateProvider: DateProvider
    private let enqueueableBucketReceptor: EnqueueableBucketReceptor
    private let logger: ContextualLogger
    private let version: Version
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider

    public init(
        bucketGenerator: BucketGenerator,
        bucketSplitInfo: BucketSplitInfo,
        dateProvider: DateProvider,
        enqueueableBucketReceptor: EnqueueableBucketReceptor,
        logger: ContextualLogger,
        version: Version,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider
    ) {
        self.bucketGenerator = bucketGenerator
        self.bucketSplitInfo = bucketSplitInfo
        self.dateProvider = dateProvider
        self.enqueueableBucketReceptor = enqueueableBucketReceptor
        self.logger = logger
        self.version = version
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
    }
    
    public func enqueue(
        testEntryConfigurations: [TestEntryConfiguration],
        testSplitter: TestSplitter,
        prioritizedJob: PrioritizedJob
    ) throws {
        let buckets = bucketGenerator.generateBuckets(
            testEntryConfigurations: testEntryConfigurations,
            splitInfo: bucketSplitInfo,
            testSplitter: testSplitter
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
        
        logger.trace("Enqueued \(buckets.count) buckets for job '\(prioritizedJob)'")
        for bucket in buckets {
            logger.trace("-- \(bucket.bucketId) with payload \(bucket.payloadContainer)")
        }
    }
}
