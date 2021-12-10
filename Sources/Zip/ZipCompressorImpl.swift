import Foundation
import PathLib
import ProcessController

public final class ZipCompressorImpl: ZipCompressor {
    private let processControllerProvider: ProcessControllerProvider
    
    public init(processControllerProvider: ProcessControllerProvider) {
        self.processControllerProvider = processControllerProvider
    }
    
    public func createArchive(
        archivePath: AbsolutePath,
        workingDirectory: AbsolutePath,
        contentsToCompress: RelativePath
    ) throws -> AbsolutePath {
        let controller = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/zip", archivePath.pathString, "-r", contentsToCompress.pathString],
                workingDirectory: workingDirectory
            )
        )
        try controller.startAndWaitForSuccessfulTermination()
        if archivePath.extension.isEmpty {
            return archivePath.appending(extension: "zip")
        } else {
            return archivePath
        }
    }
}
