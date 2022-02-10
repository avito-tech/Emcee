import Foundation
import QueueModels
import UniqueIdentifierGenerator

public struct UnsplitBucketSplitter: TestSplitter {
    public init() {}
    
    public func split(
        configuredTestEntries: [ConfiguredTestEntry],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[ConfiguredTestEntry]] {
        return [configuredTestEntries]
    }
}
