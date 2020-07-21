import Foundation
import QueueModels
import UniqueIdentifierGenerator

public final class EquallyDividedBucketSplitter: BucketSplitter {
    public init(uniqueIdentifierGenerator: UniqueIdentifierGenerator) {
        super.init(
            description: "Equally divided strategy",
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
    
    public override func split(inputs: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [[TestEntryConfiguration]] {
        let size = UInt(ceil(Double(inputs.count) / Double(bucketSplitInfo.numberOfWorkers)))
        return inputs.splitToChunks(withSize: size)
    }
}
