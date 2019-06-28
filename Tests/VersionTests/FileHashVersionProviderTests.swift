import Extensions
import FileHasher
import Foundation
import TemporaryStuff
import Version
import XCTest

final class FileHashVersionProviderTests: XCTestCase {
    let contentsToHash = "contents".data(using: .utf8)!
    
    lazy var tempFile: TemporaryFile = {
        let tempFile = try! TemporaryFile(deleteOnDealloc: true)
        tempFile.fileHandleForWriting.write(contentsToHash)
        tempFile.fileHandleForWriting.synchronizeFile()
        return tempFile
    }()
    
    func test() throws {
        let versionProvider = FileHashVersionProvider(url: tempFile.absolutePath.fileUrl)
        XCTAssertEqual(
            try versionProvider.version(),
            Version(value: contentsToHash.avito_sha256Hash().avito_hashStringFromSha256HashData())
        )
    }
}
