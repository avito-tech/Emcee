import Foundation
import PathLib
import TestHelpers
import Zip

open class FakeZipCompressor: ZipCompressor {
    public var handler: (AbsolutePath, AbsolutePath, RelativePath) throws -> AbsolutePath
    
    public init(
        handler: @escaping (AbsolutePath, AbsolutePath, RelativePath) throws -> AbsolutePath = { archivePath, _, _ in
            archivePath
        }
    ) {
        self.handler = handler
    }
    
    public func createArchive(
        archivePath: AbsolutePath,
        workingDirectory: AbsolutePath,
        contentsToCompress: RelativePath
    ) throws -> AbsolutePath {
        try handler(archivePath, workingDirectory, contentsToCompress)
    }
}
