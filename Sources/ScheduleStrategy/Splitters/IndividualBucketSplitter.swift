import Foundation
import QueueModels
import UniqueIdentifierGenerator

public struct IndividualBucketSplitter: TestSplitter {
    public init() {}
    
    public func split(
        testEntryConfigurations: [TestEntryConfiguration],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[TestEntryConfiguration]] {
        return testEntryConfigurations.map { [$0] }
    }
}
