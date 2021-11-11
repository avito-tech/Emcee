import Foundation
import QueueModels

public protocol TestSplitter {
    func split(
        testEntryConfigurations: [TestEntryConfiguration],
        bucketSplitInfo: BucketSplitInfo
    ) -> [[TestEntryConfiguration]]
}
