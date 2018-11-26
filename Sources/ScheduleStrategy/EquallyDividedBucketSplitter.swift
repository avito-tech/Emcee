import Foundation
import Models
import Extensions

public final class EquallyDividedBucketSplitter: BucketSplitter {
    public init() {
        super.init(description: "Equally divided strategy")
    }
    
    public override func split(inputs: [TestEntry], bucketSplitInfo: BucketSplitInfo) -> [[TestEntry]] {
        let size = UInt(ceil(Double(inputs.count) / Double(bucketSplitInfo.numberOfDestinations)))
        return inputs.splitToChunks(withSize: size)
    }
}
