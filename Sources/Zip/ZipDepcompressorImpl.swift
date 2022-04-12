import Foundation
import PathLib
import ProcessController

public final class ZipDecompressorImpl: ZipDecompressor {
    
    private let processControllerProvider: ProcessControllerProvider
    
    public init(
        processControllerProvider: ProcessControllerProvider
    ) {
        self.processControllerProvider = processControllerProvider
    }
    
    /// Decompresses an archive at `archivePath` to `extractionPath` directory
    public func decompress(
        archivePath: AbsolutePath,
        extractionPath: AbsolutePath
    ) throws {
        try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/unzip", archivePath, "-d", extractionPath]
            )
        ).startAndWaitForSuccessfulTermination()
    }
}
