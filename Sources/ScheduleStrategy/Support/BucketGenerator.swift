import Foundation
import EmceeLogging
import QueueModels
import UniqueIdentifierGenerator

public protocol BucketGenerator {
    func generateBuckets(
        configuredTestEntries: [ConfiguredTestEntry],
        splitInfo: BucketSplitInfo,
        testSplitter: TestSplitter
    ) -> [Bucket]
}
