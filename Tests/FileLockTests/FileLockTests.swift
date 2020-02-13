import Foundation
import FileLock
import XCTest

final class FileLockTests: XCTestCase {
    let tmp = NSTemporaryDirectory() as NSString
    lazy var uniqueTempFile = tmp.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString + ".lock")
    
    func test__lock_unlock() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        XCTAssertNoThrow(try fileLock.lock())
        XCTAssertNoThrow(try fileLock.unlock())
    }
    
    func test__paired_lock_and_unlock() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        XCTAssertNoThrow(try fileLock.lock())
        XCTAssertNoThrow(try fileLock.unlock())
        
        XCTAssertNoThrow(try fileLock.lock())
        XCTAssertNoThrow(try fileLock.unlock())
    }
    
    func test__recursive_lock() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        XCTAssertNoThrow(try fileLock.lock())
        XCTAssertNoThrow(try fileLock.lock())
        
        XCTAssertTrue(fileLock.isLocked)
        XCTAssertNoThrow(try fileLock.unlock())
        XCTAssertTrue(fileLock.isLocked)
        XCTAssertNoThrow(try fileLock.unlock())
        XCTAssertFalse(fileLock.isLocked)
    }
    
    func test__lock_on_same_file_from_different_locks() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        let otherSameFileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        XCTAssertNoThrow(try fileLock.lock())
        XCTAssertFalse(otherSameFileLock.tryToLock())
        XCTAssertNoThrow(try fileLock.unlock())
        
        XCTAssertTrue(otherSameFileLock.tryToLock())
        XCTAssertNoThrow(try otherSameFileLock.unlock())
    }
    
    func test__try_lock() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        XCTAssertTrue(fileLock.tryToLock())
        XCTAssertTrue(fileLock.isLocked)
        XCTAssertNoThrow(try fileLock.unlock())
    }
    
    func test__unbalanced_calls() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        XCTAssertThrowsError(try fileLock.unlock())
    }
    
    func test__unexisting_path_throws() throws {
        XCTAssertThrowsError(
            try FileLock(lockFilePath: tmp.appendingPathComponent("\(UUID().uuidString)/\(ProcessInfo.processInfo.globallyUniqueString)"))
        )
    }
    
    func test__while_locked() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        try fileLock.whileLocked {
            XCTAssertTrue(fileLock.isLocked)
        }
        
        XCTAssertFalse(fileLock.isLocked)
    }
    
    func test__while_locked_throws___on_unbalanced_unlock() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        XCTAssertThrowsError(
            try fileLock.whileLocked {
                XCTAssertNoThrow(try fileLock.unlock())
            }
        )
    }
    
    func test__while_locked_correctly_unlocks___when_closure_throws_error() throws {
        let fileLock = try FileLock(lockFilePath: uniqueTempFile)
        
        XCTAssertThrowsError(
            try fileLock.whileLocked {
                throw CocoaError.error(CocoaError.Code.fileReadCorruptFile, userInfo: nil, url: nil)
            }
        )
        
        XCTAssertFalse(fileLock.isLocked)
    }
}

