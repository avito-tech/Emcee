import FileCache
import Foundation
import TemporaryStuff
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class FileCacheTests: XCTestCase {
    var tempFolder: TemporaryFolder!
    
    override func setUp() {
        continueAfterFailure = false
        XCTAssertNoThrow(
            tempFolder = try TemporaryFolder(deleteOnDealloc: true)
        )
    }
    
    override func tearDown() {
        tempFolder = nil
    }
    
    func test__storing_with_copy_operation() throws {
        let cache = FileCache(cachesUrl: tempFolder.absolutePath.fileUrl)
        XCTAssertFalse(cache.contains(itemWithName: "item"))
        
        XCTAssertNoThrow(try cache.store(itemAtURL: URL(fileURLWithPath: #file), underName: "item", operation: .copy))
        let cacheUrl = try cache.url(forItemWithName: "item")
        XCTAssertTrue(cache.contains(itemWithName: "item"))
        XCTAssertEqual(cacheUrl.lastPathComponent, URL(fileURLWithPath: #file).lastPathComponent)
        
        let expectedContents = try String(contentsOfFile: #file)
        let actualContents = try String(contentsOfFile: cacheUrl.path)
        XCTAssertEqual(expectedContents, actualContents)
        
        XCTAssertNoThrow(try cache.remove(itemWithName: "item"))
        XCTAssertFalse(cache.contains(itemWithName: "item"))
    }
    
    func test__storing_with_move_operation() throws {
        let cache = FileCache(cachesUrl: tempFolder.absolutePath.fileUrl)
        
        let fileToStore = try tempFolder.createFile(
            components: [],
            filename: "source.swift",
            contents: Data(contentsOf: URL(fileURLWithPath: #file))
        )
        
        XCTAssertNoThrow(
            try cache.store(itemAtURL: fileToStore.fileUrl, underName: "item", operation: .move)
        )
        XCTAssertTrue(cache.contains(itemWithName: "item"))
        
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileToStore.pathString))
    }
    
    func testEvicting() throws {
        let cache = FileCache(cachesUrl: tempFolder.absolutePath.fileUrl)
        
        try cache.store(itemAtURL: URL(fileURLWithPath: #file), underName: "item", operation: .copy)
        XCTAssertTrue(cache.contains(itemWithName: "item"))
        
        try cache.cleanUpItems(olderThan: Date.distantFuture)
        XCTAssertFalse(cache.contains(itemWithName: "item"))
    }
    
    func test__evicting_busy_items___moves_them_to_evicting_state() throws {
        let cache = FileCache(
            cachesUrl: tempFolder.absolutePath.fileUrl,
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator(value: "someid")
        )
        
        try cache.store(itemAtURL: URL(fileURLWithPath: #file), underName: "item", operation: .copy)
        let pathToBusyFile = try cache.url(forItemWithName: "item")
        let expectedEvictingContainerPath = tempFolder.pathWith(
            components: [
                [
                    "evicting",
                    "someid",
                    pathToBusyFile.deletingLastPathComponent().lastPathComponent
                ].joined(separator: "_")
            ]
        )
        
        try FileManager.default.setAttributes([.immutable: true], ofItemAtPath: pathToBusyFile.path)
        defer {
            do {
                let expectedPath = expectedEvictingContainerPath
                    .appending(component: (#file as NSString).lastPathComponent)
                try FileManager.default.setAttributes([.immutable: false], ofItemAtPath: expectedPath.pathString)
            } catch {
                print(error)
            }
        }
        
        XCTAssertThrowsError(
            try cache.remove(itemWithName: "item"),
            "Should throw as file is locked above"
        )
        
        let tempFolderContents = try FileManager.default.contentsOfDirectory(
            atPath: tempFolder.absolutePath.pathString
        )
        
        XCTAssertEqual(
            tempFolderContents,
            [expectedEvictingContainerPath.lastComponent]
        )
    }
}
