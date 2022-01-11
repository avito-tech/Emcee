import XCTest
@testable import EmceeSample

class EmceeSampleTestsWithHost: XCTestCase {

    func test_0___from_tests_with_host___that_always_succeeds() throws {
        XCTAssert(true)
    }
    
    func test_1___from_tests_with_host___that_always_succeeds() throws {
        XCTAssert(1 == 1)
    }
    
    func test_2___from_tests_with_host___that_always_succeeds() throws {
        XCTAssert([].isEmpty)
    }
    
    func test___from_tests_with_host___that_always_fails() {
        ViewController().raiseException()
    }

}
