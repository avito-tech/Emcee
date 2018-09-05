import Basic
import FileCache
import Foundation
import XCTest

public final class FileCacheTests: XCTestCase {
    func testStorage() throws {
        let tempFolder = try TemporaryDirectory(removeTreeOnDeinit: true)
        let cache = FileCache(cachesUrl: URL(fileURLWithPath: tempFolder.path.asString))
        XCTAssertFalse(try cache.contains(itemWithName: "item"))
        
        XCTAssertNoThrow(try cache.store(itemAtURL: URL(fileURLWithPath: #file), underName: "item"))
        let cacheUrl = try cache.url(forItemWithName: "item")
        XCTAssertTrue(try cache.contains(itemWithName: "item"))
        XCTAssertEqual(cacheUrl.lastPathComponent, URL(fileURLWithPath: #file).lastPathComponent)
        
        let expectedContents = try String(contentsOfFile: #file)
        let actualContents = try String(contentsOfFile: cacheUrl.path)
        XCTAssertEqual(expectedContents, actualContents)
        
        XCTAssertNoThrow(try cache.remove(itemWithName: "item"))
        XCTAssertFalse(try cache.contains(itemWithName: "item"))
    }
}
