import Foundation
import PathLib

public protocol ZipDecompressor {
    
    /// Decompresses an archive at `archivePath` to `extractionPath` directory
    func decompress(
        archivePath: AbsolutePath,
        extractionPath: AbsolutePath
    ) throws
}
