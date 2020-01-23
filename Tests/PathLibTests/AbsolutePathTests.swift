import Foundation
import PathLib
import XCTest

class AbsolutePathTests: XCTestCase {
    
    func test___create_from_components___file_path() {
        let path = AbsolutePath(components: ["one", "two", "file"])
        XCTAssertEqual(
            path.pathString,
            "/one/two/file"
        )
    }
    
    func test___removing_last_component() {
        let path = AbsolutePath(components: ["one", "two", "file"])
        XCTAssertEqual(
            path.removingLastComponent.pathString,
            "/one/two"
        )
    }
    
    func test___last_component() {
        let path = AbsolutePath(components: ["one", "two", "file"])
        XCTAssertEqual(
            path.lastComponent,
            "file"
        )
    }
    
    func test___last_component___when_absolute_path_is_root() {
        let path = AbsolutePath(components: [])
        XCTAssertEqual(
            path.lastComponent,
            "/"
        )
    }
    
    func test___removing_last_path_component_from_componentless_path() {
        let path = AbsolutePath(components: [])
        XCTAssertEqual(
            path.removingLastComponent.pathString,
            "/"
        )
    }
    
    func test___relative_path_computation() {
        let anchor = AbsolutePath("/one/two")
        let path = AbsolutePath("/one/two/three/four")

        XCTAssertEqual(
            path.relativePath(anchorPath: anchor),
            RelativePath("three/four")
        )
    }
    
    func test___relative_path_computation_reversed() {
        let path = AbsolutePath("/one/two")
        let anchor = AbsolutePath("/one/two/three/four")
        
        XCTAssertEqual(
            path.relativePath(anchorPath: anchor),
            RelativePath("../..")
        )
    }
    
    func test___is_subpath() {
        XCTAssertTrue(
            AbsolutePath("/path/to/something").isSubpathOf(anchorPath: AbsolutePath("/path/to/"))
        )
        XCTAssertFalse(
            AbsolutePath("/path/to/something").isSubpathOf(anchorPath: AbsolutePath("/path/to/something"))
        )
        XCTAssertFalse(
            AbsolutePath("/path/of/something").isSubpathOf(anchorPath: AbsolutePath("/path/to/"))
        )
    }
}
