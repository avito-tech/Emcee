import BalancingBucketQueue
import Foundation
import Logging
import Models
import Metrics
import ScheduleStrategy

public final class TestsEnqueuer {
    private let bucketSplitInfo: BucketSplitInfo
    private let enqueueableBucketReceptor: EnqueueableBucketReceptor

    public init(
        bucketSplitInfo: BucketSplitInfo,
        enqueueableBucketReceptor: EnqueueableBucketReceptor
    ) {
        self.bucketSplitInfo = bucketSplitInfo
        self.enqueueableBucketReceptor = enqueueableBucketReceptor
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
            EnqueueTestsMetric(numberOfTests: testEntryConfigurations.count),
            EnqueueBucketsMetric(numberOfBuckets: buckets.count)
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
