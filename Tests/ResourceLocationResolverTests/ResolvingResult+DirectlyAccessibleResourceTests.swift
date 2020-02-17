import Foundation
import Models
import ResourceLocation
import ResourceLocationResolver
import XCTest

final class ResolvingResult_DirectlyAccessibleResourceTests: XCTestCase {
    func test___local_file_is_directly_accessible() {
        let resolvingResult = ResolvingResult.directlyAccessibleFile(path: "path")
        XCTAssertEqual(try resolvingResult.directlyAccessibleResourcePath(), "path")
    }
    
    func test___archive_with_file_is_directly_accessible() {
        let resolvingResult = ResolvingResult.contentsOfArchive(containerPath: "archive", filenameInArchive: "file")
        XCTAssertEqual(try resolvingResult.directlyAccessibleResourcePath(), "archive/file")
    }
    
    func test___archive_without_file_is_not_directly_accessible() {
        let resolvingResult = ResolvingResult.contentsOfArchive(containerPath: "archive", filenameInArchive: nil)
        XCTAssertThrowsError(try resolvingResult.directlyAccessibleResourcePath())
    }
}
