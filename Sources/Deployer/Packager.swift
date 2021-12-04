import Foundation
import PathLib
import ProcessController
import Tmp

/** Packs DeployableItem, returns URL to a single file with a package. */
public final class Packager {
    private let fileManager = FileManager()
    private let processControllerProvider: ProcessControllerProvider
    
    public init(processControllerProvider: ProcessControllerProvider) {
        self.processControllerProvider = processControllerProvider
    }
    
    /**
     * Packs a given DeployableItem into provided temporary folder and returns a URL to the package.
     * If the DeployableItem has been already packed, it will return URL without re-packing it.
     */
    public func preparePackage(deployable: DeployableItem, packageFolder: AbsolutePath) throws -> AbsolutePath {
        let archivePath = deployable.name.components(separatedBy: "/").reduce(packageFolder) { $0.appending($1) }
        try fileManager.createDirectory(atPath: archivePath.removingLastComponent)

        if fileManager.fileExists(atPath: archivePath.pathString) {
            return archivePath
        }
        
        let temporaryFolder = try TemporaryFolder()
        
        for file in deployable.files {
            let containerPath = file.destination.removingLastComponent
            if !fileManager.fileExists(atPath: containerPath.pathString) {
                _ = try temporaryFolder.createDirectory(components: containerPath.components)
            }
            try fileManager.copyItem(
                atPath: file.source.pathString,
                toPath: temporaryFolder.absolutePath.appending(relativePath: file.destination).pathString
            )
        }
        
        let controller = try processControllerProvider.createProcessController(
            subprocess: Subprocess(
                arguments: ["/usr/bin/zip", archivePath.pathString, "-r", "."],
                workingDirectory: temporaryFolder.absolutePath
            )
        )
        try controller.startAndListenUntilProcessDies()
        if archivePath.extension.isEmpty {
            return archivePath.appending(extension: "zip")
        } else {
            return archivePath
        }
    }
}
