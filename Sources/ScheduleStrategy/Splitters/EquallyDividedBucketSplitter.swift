import Foundation
import QueueModels
import UniqueIdentifierGenerator

public struct EquallyDividedBucketSplitter: TestSplitter {
    public init() {}
    
    public func split(
        testEntryConfigurations: [TestEntryConfiguration],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[TestEntryConfiguration]] {
        let size = UInt(
            ceil(Double(testEntryConfigurations.count) / Double(bucketSplitInfo.numberOfParallelBuckets))
        )
        return testEntryConfigurations.splitToChunks(withSize: size)
    }
}
