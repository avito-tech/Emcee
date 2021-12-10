import Foundation
import PathLib

public protocol ZipCompressor {
    
    /// Creates a new archive. It will compress contents of `path` directory recursively.
    /// - Returns: Path to created ZIP archive. Returned path may be altered. E.g. if you provide `archivePath` without `zip` extension, it will be added implicitly.
    func createArchive(
        archivePath: AbsolutePath,
        workingDirectory: AbsolutePath,
        contentsToCompress: RelativePath
    ) throws -> AbsolutePath
}
