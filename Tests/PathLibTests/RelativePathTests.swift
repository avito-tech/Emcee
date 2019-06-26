import Foundation
import PathLib
import XCTest

class RelativePathTests: XCTestCase {
    func test() {
        let path = RelativePath(components: ["one", "two"])
        XCTAssertEqual(path.pathString, "one/two")
    }
    
    func test___empty_components() {
        XCTAssertEqual(
            RelativePath(components: []).pathString,
            "./"
        )
    }
    
    func test___removing_last_path_component() {
        let path = RelativePath(components: ["two"])
        XCTAssertEqual(
            path.removingLastComponent.pathString,
            "./"
        )
    }
    
    func test___removing_last_path_component_from_componentless_path() {
        let path = RelativePath(components: [])
        XCTAssertEqual(
            path.removingLastComponent.pathString,
            "./"
        )
    }
}
