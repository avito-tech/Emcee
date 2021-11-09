import Foundation
import QueueModels
import UniqueIdentifierGenerator

public final class EquallyDividedBucketSplitter: BucketSplitter {
    public override func split(inputs: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [[TestEntryConfiguration]] {
        let size = UInt(ceil(Double(inputs.count) / Double(bucketSplitInfo.numberOfParallelBuckets)))
        return inputs.splitToChunks(withSize: size)
    }
}
