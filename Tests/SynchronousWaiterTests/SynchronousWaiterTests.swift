import Foundation
import SynchronousWaiter
import XCTest

class SynchronousWaiterTest: XCTestCase {
    func testWaitWithinRunloop() {
        let expectedDuration = 0.75
        let start = Date()
        SynchronousWaiter().wait(pollPeriod: 0.01, timeout: expectedDuration, description: "")
        let actualDuration = Date().timeIntervalSince(start)
        XCTAssertEqual(actualDuration, expectedDuration, accuracy: 0.1)
    }
    
    func testWaitFromEmptyRunLoop() {
        let expectedDuration = 0.1
        var actualDuration = 0.0
        
        let queue = OperationQueue()
        queue.addOperation {
            let start = Date()
            SynchronousWaiter().wait(pollPeriod: 0.01, timeout: expectedDuration, description: "")
            actualDuration = Date().timeIntervalSince(start)
        }
        queue.waitUntilAllOperationsAreFinished()
        
        XCTAssertEqual(actualDuration, expectedDuration, accuracy: 0.1)
    }
    
    func testWaitTimeout() {
        XCTAssertThrowsError(
            try SynchronousWaiter().waitWhile(pollPeriod: 0.01, timeout: 0.1, description: "") { true },
            "Wait should throw specific exception on time out") { errorThrown in
                guard let error = errorThrown as? TimeoutError else {
                    XCTFail("Unexpected error type")
                    return
                }
                switch error {
                case .waitTimeout(let timeout):
                    XCTAssertEqual(timeout.value, 0.1, accuracy: 0.01)
                }
        }
    }
}
