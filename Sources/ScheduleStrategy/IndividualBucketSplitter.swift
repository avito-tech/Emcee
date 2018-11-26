import Foundation
import Models

public final class IndividualBucketSplitter: BucketSplitter {
    public init() {
        super.init(description: "Individual strategy")
    }
    
    public override func split(inputs: [TestEntry], bucketSplitInfo: BucketSplitInfo) -> [[TestEntry]] {
        return inputs.map { [$0] }
    }
}
