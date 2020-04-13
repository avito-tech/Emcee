import FileSystem
import Foundation
import PathLib
import TemporaryStuff
import TestHelpers
import XCTest

final class DefaultFileSystemEnumeratorTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder(deleteOnDealloc: true) }
    
    func test___enumerating___complete() throws {
        let expectedPaths = try createTestDataForEnumeration(tempFolder: tempFolder)
        
        let enumerator = DefaultFileSystemEnumerator(
            fileManager: FileManager(),
            path: tempFolder.absolutePath
        )
        
        var paths = Set<AbsolutePath>()
        try enumerator.each { (path: AbsolutePath) in
            paths.insert(path)
        }
        
        XCTAssertEqual(expectedPaths, paths)
    }
}
