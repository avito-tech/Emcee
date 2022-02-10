import Foundation
import QueueModels

public protocol TestSplitter {
    func split(
        configuredTestEntries: [ConfiguredTestEntry],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[ConfiguredTestEntry]]
}
