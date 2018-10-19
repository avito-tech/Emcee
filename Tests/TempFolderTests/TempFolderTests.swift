import Foundation
import TempFolder
import XCTest

final class TempFolderTests: XCTestCase {
    func testCreatingTempFolder() throws {
        XCTAssertNoThrow(try TempFolder())
    }
    
    func testCreatingFolders() throws {
        let tempFolder = try TempFolder()
        let path = try tempFolder.pathByCreatingDirectories(components: ["a", "b", "c"])
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: path.asString, isDirectory: &isDir))
        XCTAssertTrue(isDir.boolValue)
    }
    
    func testCreaintFile() throws {
        let tempFolder = try TempFolder()
        let contents = "hello"
        let path = try tempFolder.createFile(components: ["a", "b"], filename: "file.txt", contents: contents.data(using: .utf8))
        
        var isDir: ObjCBool = false
        XCTAssertTrue(FileManager.default.fileExists(atPath: path.asString, isDirectory: &isDir))
        XCTAssertFalse(isDir.boolValue)
        
        let actualContents = try String(contentsOfFile: path.asString)
        XCTAssertEqual(contents, actualContents)
    }
}
