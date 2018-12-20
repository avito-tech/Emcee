import Extensions
import Foundation
import XCTest

final class DictionaryMergingTests: XCTestCase {
    func test() {
        let input = ["a": 1]
        let output = input.byMergingWith(["b": 1])
        XCTAssertEqual(output, ["a": 1, "b": 1])
    }
}

