import Foundation
import QueueModels
import RunnerModels
import SimulatorPoolModels

public struct EnqueuedRunIosTestsPayload: Hashable {
    public let bucketId: BucketId
    public let testDestination: TestDestination
    public let testEntries: [TestEntry]
    public let numberOfRetries: UInt
    
    public init(
        bucketId: BucketId,
        testDestination: TestDestination,
        testEntries: [TestEntry],
        numberOfRetries: UInt
    ) {
        self.bucketId = bucketId
        self.testDestination = testDestination
        self.testEntries = testEntries
        self.numberOfRetries = numberOfRetries
    }
}
