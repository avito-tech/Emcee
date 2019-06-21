import Basic
import Extensions
import Foundation
import FileHasher
import Version
import XCTest

final class FileHashVersionProviderTests: XCTestCase {
    let contentsToHash = "contents".data(using: .utf8)!
    
    lazy var tempFile: TemporaryFile = {
        let tempFile = try! TemporaryFile(deleteOnClose: true)
        tempFile.fileHandle.write(contentsToHash)
        tempFile.fileHandle.synchronizeFile()
        return tempFile
    }()
    
    func test() throws {
        let versionProvider = FileHashVersionProvider(url: URL(fileURLWithPath: tempFile.path.pathString))
        XCTAssertEqual(
            try versionProvider.version(),
            Version(value: contentsToHash.avito_sha256Hash().avito_hashStringFromSha256HashData())
        )
    }
}
