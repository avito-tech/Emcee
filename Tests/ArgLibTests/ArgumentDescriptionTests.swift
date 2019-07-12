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
    
    func test___usage_as_optional() {
        let description = ArgumentDescription(name: .doubleDashed(dashlessName: "name"), overview: "Text").asOptional
        XCTAssertEqual(
            description.usage,
            "--name   --   Text. Optional."
        )
    }
    
    func test___usage_as_required() {
        let description = ArgumentDescription(name: .doubleDashed(dashlessName: "name"), overview: "Text").asRequired
        XCTAssertEqual(
            description.usage,
            "--name   --   Text. Required."
        )
    }
    
    func test___usage_as_multiple() {
        let description = ArgumentDescription(name: .doubleDashed(dashlessName: "name"), overview: "Text", multiple: true).asRequired
        XCTAssertEqual(
            description.usage,
            "--name   --   Text. This argument may be repeated multiple times. Required."
        )
    }
}

