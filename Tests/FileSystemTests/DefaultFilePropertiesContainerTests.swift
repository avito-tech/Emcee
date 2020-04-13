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
    
    func test___properties_for_nonexisting_file() {
        let properties = DefaultFilePropertiesContainer(path: temporaryFile.absolutePath.appending(component: "nonexisting"))
        assertThrows {
            _ = try properties.modificationDate()
        }
    }
}
