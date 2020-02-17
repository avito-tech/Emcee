import Foundation
import QueueModels
import XCTest

final class PriorityTests: XCTestCase {
    func test___creating_out_of_bound_priority_throws() {
        XCTAssertThrowsError(try Priority(intValue: 1000))
    }
    
    func test___comparing_priorities() {
        XCTAssertLessThan(try Priority(intValue: 1), try Priority(intValue: 2))
    }
    
    func test___equality() {
        XCTAssertEqual(try Priority(intValue: 1), try Priority(intValue: 1))
    }
}

