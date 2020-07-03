import FileSystem
import Foundation
import TemporaryStuff
import TestHelpers
import XCTest

final class DefaultFilePropertiesContainerTests: XCTestCase {
    private lazy var temporaryFile = assertDoesNotThrow { try TemporaryFile(deleteOnDealloc: true) }
    private lazy var filePropertiesContainer = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath)
    
    func test___modificationDate() {
        XCTAssertEqual(
            try filePropertiesContainer.modificationDate(),
            try temporaryFile.absolutePath.fileUrl.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
        )
    }
    
    func test___setting_modificationDate() throws {
        let date = Date(timeIntervalSince1970: 1000)
        
        try filePropertiesContainer.set(modificationDate: date)
        
        XCTAssertEqual(
            try temporaryFile.absolutePath.fileUrl.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate,
            date
        )
    }
    
    func test___properties_for_nonexisting_file() {
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath.appending(component: "nonexisting"))
        assertThrows {
            try properties.modificationDate()
        }
    }
    
    func test___is_executable___when_not_executable() throws {
        try FileManager().setAttributes(
            [.posixPermissions: 700],
            ofItemAtPath: temporaryFile.absolutePath.pathString
        )
        
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath)
        XCTAssertFalse(try properties.isExecutable())
    }
    
    func test___is_executable___when_executable() throws {
        try FileManager().setAttributes(
            [.posixPermissions: 707],
            ofItemAtPath: temporaryFile.absolutePath.pathString
        )
        
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath)
        XCTAssertTrue(try properties.isExecutable())
    }
    
    func test___exists___when_exists() throws {
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath)
        XCTAssertTrue(try properties.exists())
    }
    
    func test___not_exists___when_not_exists() throws {
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath.appending(component: "nonexisting"))
        XCTAssertFalse(try properties.exists())
    }
    
    func test___is_directory___for_directory() throws {
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath.removingLastComponent)
        XCTAssertTrue(try properties.isDirectory())
    }
    
    func test___is_not_directory___for_non_directories() throws {
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath)
        XCTAssertFalse(try properties.isDirectory())
    }
    
    func test___size() throws {
        temporaryFile.fileHandleForWriting.write(Data([0x00, 0x01, 0x02]))
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath)
        XCTAssertEqual(try properties.size(), 3)
    }
}
