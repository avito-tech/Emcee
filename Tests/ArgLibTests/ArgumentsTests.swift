import ArgLib
import Foundation
import XCTest

final class ArgumentsTests: XCTestCase {
    func test___array_literal() {
        XCTAssertEqual(
            Arguments([ArgumentDescription(name: .doubleDashed(dashlessName: "name"), overview: "overview")]),
            [ArgumentDescription(name: .doubleDashed(dashlessName: "name"), overview: "overview")] as Arguments
        )
    }
}
