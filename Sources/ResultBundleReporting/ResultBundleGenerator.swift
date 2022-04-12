import FileSystem
import Foundation
import PathLib
import ProcessController
import Tmp
import EmceeLogging
import ResourceLocationResolver

public final class ResultBundleGenerator {
    private enum ResultBundleGeneratorError: Error, CustomStringConvertible {
        case missingResultBundle(path: AbsolutePath)
        
        var description: String {
            switch self {
            case .missingResultBundle(let path):
                return "Missing result bundle at path \(path)"
            }
        }
    }
    
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let logger: ContextualLogger
    private let fileSystem: FileSystem
    private let resourceLocationResolver: ResourceLocationResolver
    private let zipDecompressor: ZipDecompressor
    private let uploadFolder: AbsolutePath
    
    public init(
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        logger: ContextualLogger,
        fileSystem: FileSystem,
        resourceLocationResolver: ResourceLocationResolver,
        zipDecompressor: ZipDecompressor,
        uploadFolder: AbsolutePath
    ) {
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.logger = logger
        self.fileSystem = fileSystem
        self.resourceLocationResolver = resourceLocationResolver
        self.zipDecompressor = zipDecompressor
        self.uploadFolder = uploadFolder
    }
    
    public func writeReport(
        path: String
    ) throws {
        let temporaryDirectory = try tempFolder.createDirectory(components: [])
        
        var resultBundlePaths: [AbsolutePath] = []
        
        try fileSystem.contentEnumerator(
            forPath: uploadFolder,
            style: .shallow
        ).allPaths().filter {
            try self.fileSystem.isRegularFile(path: $0)
        }.forEach { xcresultArchivePath in
            let xcresultContentsPath = temporaryDirectory.appending(
                "zipped_xcresult_\(UUID().uuidString)"
            )
            
            do {
                try zipDecompressor.decompress(
                    archivePath: xcresultArchivePath,
                    extractionPath: xcresultContentsPath
                )
            } catch {
                logger.error("Error unzipping result bundle at path \(xcresultArchivePath): \(error)")
            }
            
            let resultBundlePath = xcresultContentsPath.appending("resultBundle.xcresult")
            guard fileSystem.exists(path: resultBundlePath) else {
                logger.error("Missing result bundle at path \(resultBundlePath)")
                return
            }
            
            resultBundlePaths.append(resultBundlePath)
        }
        
        let resultBundleOutputPath = try resourceLocationResolver.resolvePath(
            resourceLocation: .localFilePath(
                path
            )
        ).directlyAccessibleResourcePath()
        
        switch resultBundlePaths.count {
        case 0:
            logger.error("No result bundles to create")
        case 1:
            try fileSystem.copy(
                source: resultBundlePaths[0],
                destination: resultBundleOutputPath,
                overwrite: true,
                ensureDirectoryExists: true
            )
        default:
            let resultBundleTemporaryOutputPath = temporaryDirectory.appending("\(UUID().uuidString)")
            let resultBundleProcessController = try processControllerProvider.createProcessController(
                subprocess: Subprocess(
                    arguments: ["/usr/bin/xcrun", "xcresulttool", "merge"]
                    + resultBundlePaths.map(\.pathString)
                    + ["--output-path", resultBundleTemporaryOutputPath.pathString]
                )
            )
            resultBundleProcessController.restreamOutput()
            try resultBundleProcessController.startAndWaitForSuccessfulTermination()
            
            try fileSystem.copy(
                source: resultBundleTemporaryOutputPath,
                destination: resultBundleOutputPath,
                overwrite: true,
                ensureDirectoryExists: true
            )
        }
    }
    
}
