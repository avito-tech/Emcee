import Foundation
import SynchronousWaiter
import TestHelpers
import XCTest

class WaiterTests: XCTestCase {
    let waiterUnderTest: Waiter = SynchronousWaiter()
    
    func test___waiting_for_unwrap___provides_result_if_provider_returns_result() {
        assertDoesNotThrow {
            let result: String = try waiterUnderTest.waitForUnwrap(
                timeout: 1,
                valueProvider: { "hello" },
                description: ""
            )
            XCTAssertEqual(result, "hello")
        }
    }
    
    func test___waiting_for_unwrap___throws_on_timeout() {
        assertThrows {
            let _: String = try waiterUnderTest.waitForUnwrap(
                timeout: 0,
                valueProvider: { nil },
                description: ""
            )
        }
    }
    
    func test___waiting_for_unwrap___throws_if_provider_throws() {
        assertThrows {
            let _: String = try waiterUnderTest.waitForUnwrap(
                timeout: 0,
                valueProvider: { throw ErrorForTestingPurposes(text: "sample error") },
                description: ""
            )
        }
    }
}
