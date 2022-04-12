import Foundation
import PathLib
import TestHelpers
import Zip

open class FakeZipDecompressor: ZipDecompressor {

    public init() { }
    
    public private(set) var decompressedPaths: [(archivePath: AbsolutePath, extractionPath: AbsolutePath)] = []
    
    public func decompress(
        archivePath: AbsolutePath,
        extractionPath: AbsolutePath
    ) throws {
        decompressedPaths.append(
            (archivePath: archivePath, extractionPath: extractionPath)
        )
    }
}
