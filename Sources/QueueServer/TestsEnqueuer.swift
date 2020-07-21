import BalancingBucketQueue
import DateProvider
import Foundation
import LocalHostDeterminer
import Logging
import Metrics
import QueueModels
import ScheduleStrategy

public final class TestsEnqueuer {
    private let bucketSplitInfo: BucketSplitInfo
    private let dateProvider: DateProvider
    private let enqueueableBucketReceptor: EnqueueableBucketReceptor
    private let version: Version

    public init(
        bucketSplitInfo: BucketSplitInfo,
        dateProvider: DateProvider,
        enqueueableBucketReceptor: EnqueueableBucketReceptor,
        version: Version
    ) {
        self.bucketSplitInfo = bucketSplitInfo
        self.dateProvider = dateProvider
        self.enqueueableBucketReceptor = enqueueableBucketReceptor
        self.version = version
    }
    
    public func enqueue(
        bucketSplitter: BucketSplitter,
        testEntryConfigurations: [TestEntryConfiguration],
        prioritizedJob: PrioritizedJob
    ) {
        let buckets = bucketSplitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: bucketSplitInfo
        )
        enqueueableBucketReceptor.enqueue(buckets: buckets, prioritizedJob: prioritizedJob)
        
        MetricRecorder.capture(
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
        
        Logger.info("Enqueued \(buckets.count) buckets for job '\(prioritizedJob)'")
        for bucket in buckets {
            Logger.verboseDebug("-- \(bucket) with tests:")
            for testEntries in bucket.testEntries {
                Logger.verboseDebug("-- -- \(testEntries)")
            }
        }
    }
}
