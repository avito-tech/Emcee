import Foundation
import QueueModels
import UniqueIdentifierGenerator

public struct FixedBucketSizeSplitter: TestSplitter {
    private let size: Int
    
    public init(size: Int) {
        self.size = size
    }
    
    public func split(
        configuredTestEntries: [ConfiguredTestEntry],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[ConfiguredTestEntry]] {
        return configuredTestEntries.splitToChunks(withSize: UInt(size))
    }
}
