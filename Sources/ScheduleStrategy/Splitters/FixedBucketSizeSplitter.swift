import Foundation
import QueueModels
import UniqueIdentifierGenerator

public struct FixedBucketSizeSplitter: TestSplitter {
    private let size: Int
    
    public init(size: Int) {
        self.size = size
    }
    
    public func split(
        testEntryConfigurations: [TestEntryConfiguration],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[TestEntryConfiguration]] {
        return testEntryConfigurations.splitToChunks(withSize: UInt(size))
    }
}
