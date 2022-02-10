import Foundation
import QueueModels
import UniqueIdentifierGenerator

public struct IndividualBucketSplitter: TestSplitter {
    public init() {}
    
    public func split(
        configuredTestEntries: [ConfiguredTestEntry],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[ConfiguredTestEntry]] {
        return configuredTestEntries.map { [$0] }
    }
}
