import ArgLib
import Foundation
import XCTest

final class ArgumentsTests: XCTestCase {
    func test___array_literal() {
        XCTAssertEqual(
            Arguments([ArgumentDescription(name: "name", overview: "overview")]),
            [ArgumentDescription(name: "name", overview: "overview")] as Arguments
        )
    }
}
