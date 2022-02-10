import CommonTestModels
import Foundation
import QueueModels

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
