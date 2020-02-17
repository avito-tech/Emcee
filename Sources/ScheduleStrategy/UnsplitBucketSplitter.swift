import Foundation
import Models
import QueueModels
import UniqueIdentifierGenerator

public final class UnsplitBucketSplitter: BucketSplitter {
    public init(uniqueIdentifierGenerator: UniqueIdentifierGenerator) {
        super.init(
            description: "Unsplit schedule strategy",
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
    
    public override func split(
        inputs: [TestEntryConfiguration],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[TestEntryConfiguration]] {
        return [inputs]
    }
}
