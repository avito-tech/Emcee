import Foundation
import Models

public final class ContinuousBucketSplitter: BucketSplitter {
    public init() {
        super.init(description: "Continuos schedule strategy")
    }
    
    public override func split(
        inputs: [TestEntryConfiguration],
        bucketSplitInfo: BucketSplitInfo
        ) -> [[TestEntryConfiguration]]
    {
        return [inputs]
    }
}
