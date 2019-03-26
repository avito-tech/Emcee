import Foundation
import FileHasher
import TempFolder
import XCTest

final class FileHasherTests: XCTestCase {
    
    let tempFolder = try! TempFolder()
    
    func test() throws {
        let file = try tempFolder.createFile(filename: "file", contents: "contents".data(using: .utf8)!)
        
        let fileHasher = FileHasher(fileUrl: URL(fileURLWithPath: file.pathString))
        XCTAssertEqual(
            try fileHasher.hash().uppercased(),
            "D1B2A59FBEA7E20077AF9F91B27E95E865061B270BE03FF539AB3B73587882E8"
        )
    }
}

