import BuildArtifacts
import Foundation
import Models
import QueueModels
import RunnerModels

public struct TestEntryHistoryId: Hashable {
    public let bucketId: BucketId
    public let testEntry: TestEntry
    
    public init(
        bucketId: BucketId,
        testEntry: TestEntry
    ) {
        self.bucketId = bucketId
        self.testEntry = testEntry
    }
}
