import ArgLib
import Foundation
import XCTest

final class ArgumentDescriptionTests: XCTestCase {
    func test___as_optional() {
        let description = ArgumentDescription(name: .doubleDashed(dashlessName: "1"), overview: "").asOptional
        XCTAssertTrue(description.optional)
    }
    
    func test___as_required() {
        let description = ArgumentDescription(name: .doubleDashed(dashlessName: "1"), overview: "").asRequired
        XCTAssertFalse(description.optional)
    }
}

