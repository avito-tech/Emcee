import Foundation
import PathLib
import XCTest

class PathTests: XCTestCase {
    func test___empty_extension() {
        let path = AbsolutePath(components: ["file"])
        XCTAssertEqual(path.extension, "")
    }
    
    func test___extension() {
        let path = AbsolutePath(components: ["file.txt"])
        XCTAssertEqual(path.extension, "txt")
    }
    
    func test___extension_multiple_dots() {
        let path = AbsolutePath(components: ["file.aaa.txt"])
        XCTAssertEqual(path.extension, "txt")
    }
    
    func test___extension_hidden_file() {
        let path = AbsolutePath(components: [".file"])
        XCTAssertEqual(path.extension, "")
    }
    
    func test___extension_hidden_file_with_multiple_dots() {
        let path = AbsolutePath(components: [".file.aaa.txt"])
        XCTAssertEqual(path.extension, "txt")
    }
}
