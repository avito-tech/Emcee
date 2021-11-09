import Foundation
import QueueModels
import UniqueIdentifierGenerator

public final class IndividualBucketSplitter: BucketSplitter {
    public override func split(inputs: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [[TestEntryConfiguration]] {
        return inputs.map { [$0] }
    }
}
