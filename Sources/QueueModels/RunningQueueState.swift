import Foundation
import Models
import Types

public struct RunningQueueState: Equatable, CustomStringConvertible, Codable {
    public let enqueuedTests: [TestName]
    public let dequeuedTests: MapWithCollection<WorkerId, TestName>
    
    public init(
        enqueuedTests: [TestName],
        dequeuedTests: MapWithCollection<WorkerId, TestName>
    ) {
        self.enqueuedTests = enqueuedTests
        self.dequeuedTests = dequeuedTests
    }
    
    public var isDepleted: Bool {
        return enqueuedTests.isEmpty && dequeuedTests.isEmpty
    }
    
    public var description: String {
        return "<\(type(of: self)): enqueued: \(enqueuedTests.count), dequeued: \(dequeuedTests.flattenValues.count)>"
    }
}
