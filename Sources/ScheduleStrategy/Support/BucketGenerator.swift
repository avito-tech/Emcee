import Foundation
import EmceeLogging
import QueueModels
import UniqueIdentifierGenerator

public protocol BucketGenerator {
    func generateBuckets(
        testEntryConfigurations: [TestEntryConfiguration],
        splitInfo: BucketSplitInfo,
        testSplitter: TestSplitter
    ) -> [Bucket]
}
