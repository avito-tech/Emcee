import Foundation
import Models
import Extensions

public final class EquallyDividedBucketSplitter: BucketSplitter {
    public init() {
        super.init(description: "Equally divided strategy")
    }
    
    public override func split(inputs: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [[TestEntryConfiguration]] {
        let size = UInt(ceil(Double(inputs.count) / Double(bucketSplitInfo.numberOfWorkers)))
        return inputs.splitToChunks(withSize: size)
    }
}
