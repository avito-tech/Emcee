import Extensions
import Foundation
import XCTest

class StringWhitespaceRemovingTests: XCTestCase {
    func test() {
        XCTAssertEqual("string with\twhitespaces".removingWhitespaces(), "stringwithwhitespaces")
    }
}
