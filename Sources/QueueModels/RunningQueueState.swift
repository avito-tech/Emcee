import Foundation
import RunnerModels
import Types

public struct RunningQueueState: Equatable, CustomStringConvertible, Codable {
    public let enqueuedBucketCount: Int
    public let enqueuedTests: [TestName]
    public let dequeuedBucketCount: Int
    public let dequeuedTests: MapWithCollection<WorkerId, TestName>
    
    public init(
        enqueuedBucketCount: Int,
        enqueuedTests: [TestName],
        dequeuedBucketCount: Int,
        dequeuedTests: MapWithCollection<WorkerId, TestName>
    ) {
        self.enqueuedBucketCount = enqueuedBucketCount
        self.enqueuedTests = enqueuedTests
        self.dequeuedBucketCount = dequeuedBucketCount
        self.dequeuedTests = dequeuedTests
    }
    
    public var isDepleted: Bool {
        return enqueuedTests.isEmpty && dequeuedTests.isEmpty
    }
    
    public var description: String {
        return "<enqueued \(enqueuedBucketCount) buckets/\(enqueuedTests.count) tests, dequeued \(dequeuedBucketCount) buckets/\(dequeuedTests.flattenValues.count) tests>"
    }
}
