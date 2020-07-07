import BalancingBucketQueue
import DateProvider
import Foundation
import Logging
import Metrics
import Models
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
                numberOfTests: testEntryConfigurations.count,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            EnqueueBucketsMetric(
                numberOfBuckets: buckets.count,
                version: version,
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
