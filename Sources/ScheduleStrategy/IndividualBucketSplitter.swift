import Foundation
import Models
import UniqueIdentifierGenerator

public final class IndividualBucketSplitter: BucketSplitter {
    public init(uniqueIdentifierGenerator: UniqueIdentifierGenerator) {
        super.init(
            description: "Individual strategy",
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
    
    public override func split(inputs: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [[TestEntryConfiguration]] {
        return inputs.map { [$0] }
    }
}
