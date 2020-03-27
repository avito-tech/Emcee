import Foundation
import QueueModels
import XCTest

final class PriorityDefinesPreeminenceTests: XCTestCase {
    func test() {
        XCTAssertEqual(Priority.medium.executionOrder(relativeTo: .lowest), .before)
        XCTAssertEqual(Priority.medium.executionOrder(relativeTo: .medium), .equal)
    }
}
