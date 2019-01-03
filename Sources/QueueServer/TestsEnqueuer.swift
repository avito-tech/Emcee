import BalancingBucketQueue
import Foundation
import Logging
import Models
import ScheduleStrategy

public final class TestsEnqueuer {
    private let bucketSplitter: BucketSplitter
    private let bucketSplitInfo: BucketSplitInfo
    private let enqueueableBucketReceptor: EnqueueableBucketReceptor

    public init(
        bucketSplitter: BucketSplitter,
        bucketSplitInfo: BucketSplitInfo,
        enqueueableBucketReceptor: EnqueueableBucketReceptor)
    {
        self.bucketSplitter = bucketSplitter
        self.bucketSplitInfo = bucketSplitInfo
        self.enqueueableBucketReceptor = enqueueableBucketReceptor
    }
    
    public func enqueue(testEntryConfigurations: [TestEntryConfiguration], jobId: JobId) {
        let buckets = bucketSplitter.generate(
            inputs: testEntryConfigurations,
            splitInfo: bucketSplitInfo
        )
        enqueueableBucketReceptor.enqueue(buckets: buckets, jobId: jobId)
        
        Logger.info("Enqueued \(buckets.count) buckets for job '\(jobId)'")
        for bucket in buckets {
            Logger.verboseDebug("-- \(bucket) with tests:")
            for testEntries in bucket.testEntries {
                Logger.verboseDebug("-- -- \(testEntries)")
            }
        }
    }
}
