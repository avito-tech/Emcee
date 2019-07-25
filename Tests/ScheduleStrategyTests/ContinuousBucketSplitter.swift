@testable import ScheduleStrategy
import Foundation
import Models
import UniqueIdentifierGenerator

public final class ContinuousBucketSplitter: BucketSplitter {
    public init(uniqueIdentifierGenerator: UniqueIdentifierGenerator) {
        super.init(
            description: "Continuos schedule strategy",
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
    
    public override func split(
        inputs: [TestEntryConfiguration],
        bucketSplitInfo: BucketSplitInfo
        ) -> [[TestEntryConfiguration]]
    {
        return [inputs]
    }
}
