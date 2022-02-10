import Foundation
import QueueModels
import UniqueIdentifierGenerator

public struct EquallyDividedBucketSplitter: TestSplitter {
    public init() {}
    
    public func split(
        configuredTestEntries: [ConfiguredTestEntry],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[ConfiguredTestEntry]] {
        let size = UInt(
            ceil(Double(configuredTestEntries.count) / Double(bucketSplitInfo.numberOfParallelBuckets))
        )
        return configuredTestEntries.splitToChunks(withSize: size)
    }
}
