import Foundation
import XCTest
@testable import Extensions

class StringWhitespaceRemovingTests: XCTestCase {
    func test() {
        XCTAssertEqual("string with\twhitespaces".removingWhitespaces(), "stringwithwhitespaces")
    }
}
