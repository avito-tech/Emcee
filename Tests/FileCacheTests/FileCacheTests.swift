import DateProvider
import FileCache
import FileSystem
import Foundation
import PathLib
import TemporaryStuff
import TestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class FileCacheTests: XCTestCase {
    private lazy var dateProvider = SystemDateProvider()
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private lazy var fileManager = FileManager()
    private lazy var fileSystem = LocalFileSystem()
    private lazy var cache = assertDoesNotThrow {
        try FileCache(
            cachesContainer: tempFolder.absolutePath,
            dateProvider: dateProvider,
            fileSystem: fileSystem
        )
    }
    
    override func setUp() {
        continueAfterFailure = false
    }
    
    func test__creating_cache___when_cache_path_does_not_exists() {
        XCTAssertNoThrow(
            _ = try FileCache(
                cachesContainer: tempFolder.absolutePath.appending(component: "subfolder"),
                dateProvider: dateProvider,
                fileSystem: fileSystem
            )
        )
    }
    
    func test__storing_with_copy_operation() throws {
        XCTAssertFalse(cache.contains(itemWithName: "item"))
        
        XCTAssertNoThrow(try cache.store(itemAtPath: AbsolutePath(#file), underName: "item", operation: .copy))
        let cacheUrl = try cache.path(forItemWithName: "item")
        XCTAssertTrue(cache.contains(itemWithName: "item"))
        XCTAssertEqual(cacheUrl.lastComponent, URL(fileURLWithPath: #file).lastPathComponent)
        
        let expectedContents = try String(contentsOfFile: #file)
        let actualContents = try String(contentsOfFile: cacheUrl.pathString)
        XCTAssertEqual(expectedContents, actualContents)
        
        XCTAssertNoThrow(try cache.remove(itemWithName: "item"))
        XCTAssertFalse(cache.contains(itemWithName: "item"))
    }
    
    func test__storing_with_move_operation() throws {
        let fileToStore = try tempFolder.createFile(
            components: [],
            filename: "source.swift",
            contents: Data(contentsOf: URL(fileURLWithPath: #file))
        )
        
        XCTAssertNoThrow(
            try cache.store(itemAtPath: fileToStore, underName: "item", operation: .move)
        )
        XCTAssertTrue(cache.contains(itemWithName: "item"))
        
        XCTAssertFalse(fileManager.fileExists(atPath: fileToStore.pathString))
    }
    
    func test___cleaning_up_old_items() throws {
        try cache.store(itemAtPath: AbsolutePath(#file), underName: "item", operation: .copy)
        XCTAssertTrue(cache.contains(itemWithName: "item"))
        
        try cache.cleanUpItems(olderThan: Date.distantFuture)
        XCTAssertFalse(cache.contains(itemWithName: "item"))
    }
    
    func test__evicting_busy_items___moves_them_to_evicting_state() throws {
        let cache = try FileCache(
            cachesContainer: tempFolder.absolutePath,
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator(value: "someid")
        )
        
        try cache.store(itemAtPath: AbsolutePath(#file), underName: "item", operation: .copy)
        let pathToBusyFile = try cache.path(forItemWithName: "item")
        let expectedEvictingContainerPath = tempFolder.pathWith(
            components: [
                [
                    "evicting",
                    "someid",
                    pathToBusyFile.removingLastComponent.lastComponent
                ].joined(separator: "_")
            ]
        )
        
        try fileManager.setAttributes([.immutable: true], ofItemAtPath: pathToBusyFile.pathString)
        defer {
            do {
                let expectedPath = expectedEvictingContainerPath
                    .appending(component: (#file as NSString).lastPathComponent)
                try fileManager.setAttributes([.immutable: false], ofItemAtPath: expectedPath.pathString)
            } catch {
                print(error)
            }
        }
        
        XCTAssertThrowsError(
            try cache.remove(itemWithName: "item"),
            "Should throw as file is locked above"
        )
        
        let tempFolderContents = try fileManager.contentsOfDirectory(
            atPath: tempFolder.absolutePath.pathString
        ).filter { $0.hasPrefix(FileCache.evictingStatePrefix) }
        
        XCTAssertEqual(
            tempFolderContents,
            [expectedEvictingContainerPath.lastComponent]
        )
    }
    
    func test___evicting_items_to_fit_size() throws {
        let file2kPath = try tempFolder.createFile(filename: "2k", contents: Data(repeating: 0, count: 2 * 1024))
        let file3kPath = try tempFolder.createFile(filename: "3k", contents: Data(repeating: 0, count: 3 * 1024))
        let file8kPath = try tempFolder.createFile(filename: "8k", contents: Data(repeating: 0, count: 8 * 1024))
        
        try cache.store(itemAtPath: file2kPath, underName: "2k_item", operation: .move)
        let cached2kPath = try cache.path(forItemWithName: "2k_item")
        
        try cache.store(itemAtPath: file3kPath, underName: "3k_item", operation: .move)
        let cached3kPath = try cache.path(forItemWithName: "3k_item")
        
        try cache.store(itemAtPath: file8kPath, underName: "8k_item", operation: .move)
        
        XCTAssertEqual(
            try cache.cleanUpItemsToFitToSize(sizeInBytes: 9 * 1024),
            [cached2kPath.removingLastComponent, cached3kPath.removingLastComponent]
        )
        
        XCTAssertFalse(cache.contains(itemWithName: "2k_item"))
        XCTAssertFalse(cache.contains(itemWithName: "3k_item"))
    }
    
    func test___evicting_items_to_fit_zero_bytes___removes_all_items() throws {
        let file2kPath = try tempFolder.createFile(filename: "2k", contents: Data(repeating: 0, count: 2 * 1024))
        let file3kPath = try tempFolder.createFile(filename: "3k", contents: Data(repeating: 0, count: 3 * 1024))
        let file8kPath = try tempFolder.createFile(filename: "8k", contents: Data(repeating: 0, count: 8 * 1024))
        
        try cache.store(itemAtPath: file2kPath, underName: "2k_item", operation: .move)
        let cached2kPath = try cache.path(forItemWithName: "2k_item")
        
        try cache.store(itemAtPath: file3kPath, underName: "3k_item", operation: .move)
        let cached3kPath = try cache.path(forItemWithName: "3k_item")
        
        try cache.store(itemAtPath: file8kPath, underName: "8k_item", operation: .move)
        let cached8kPath = try cache.path(forItemWithName: "8k_item")
        
        XCTAssertEqual(
            try cache.cleanUpItemsToFitToSize(sizeInBytes: 0),
            [cached2kPath.removingLastComponent, cached3kPath.removingLastComponent, cached8kPath.removingLastComponent]
        )
        
        XCTAssertFalse(cache.contains(itemWithName: "2k_item"))
        XCTAssertFalse(cache.contains(itemWithName: "3k_item"))
        XCTAssertFalse(cache.contains(itemWithName: "8k_item"))
    }
    
    func test___evicting_items_to_fir_huge_amount_of_bytes___does_not_remove_anything() throws {
        let file2kPath = try tempFolder.createFile(filename: "2k", contents: Data(repeating: 0, count: 2 * 1024))
        
        try cache.store(itemAtPath: file2kPath, underName: "2k_item", operation: .move)
        
        XCTAssertEqual(
            try cache.cleanUpItemsToFitToSize(sizeInBytes: 100 * 1024),
            []
        )
        
        XCTAssertTrue(cache.contains(itemWithName: "2k_item"))
    }
}
