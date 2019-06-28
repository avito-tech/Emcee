import FileCache
import Foundation
import TemporaryStuff
import XCTest

public final class FileCacheTests: XCTestCase {
    let tempFolder = try! TemporaryFolder(deleteOnDealloc: true)
    
    func testStorage() throws {
        let cache = FileCache(cachesUrl: tempFolder.absolutePath.fileUrl)
        XCTAssertFalse(cache.contains(itemWithName: "item"))
        
        XCTAssertNoThrow(try cache.store(itemAtURL: URL(fileURLWithPath: #file), underName: "item"))
        let cacheUrl = try cache.url(forItemWithName: "item")
        XCTAssertTrue(cache.contains(itemWithName: "item"))
        XCTAssertEqual(cacheUrl.lastPathComponent, URL(fileURLWithPath: #file).lastPathComponent)
        
        let expectedContents = try String(contentsOfFile: #file)
        let actualContents = try String(contentsOfFile: cacheUrl.path)
        XCTAssertEqual(expectedContents, actualContents)
        
        XCTAssertNoThrow(try cache.remove(itemWithName: "item"))
        XCTAssertFalse(cache.contains(itemWithName: "item"))
    }
    
    func testEvicting() throws {
        let cache = FileCache(cachesUrl: tempFolder.absolutePath.fileUrl)
        
        try cache.store(itemAtURL: URL(fileURLWithPath: #file), underName: "item")
        XCTAssertTrue(cache.contains(itemWithName: "item"))
        
        try cache.cleanUpItems(olderThan: Date.distantFuture)
        XCTAssertFalse(cache.contains(itemWithName: "item"))
    }
}
