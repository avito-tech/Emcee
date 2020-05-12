import Foundation
import Logging
import PathLib
import ProcessController
import TemporaryStuff

/** Packs DeployableItem, returns URL to a single file with a package. */
public final class Packager {
    private let processControllerProvider: ProcessControllerProvider
    
    public init(processControllerProvider: ProcessControllerProvider) {
        self.processControllerProvider = processControllerProvider
    }
    
    /**
     * Packs a given DeployableItem into provided temporary folder and returns a URL to the package.
     * If the DeployableItem has been already packed, it will return URL without re-packing it.
     */
    public func preparePackage(deployable: DeployableItem, packageFolder: AbsolutePath) throws -> AbsolutePath {
        let archivePath = deployable.name.components(separatedBy: "/").reduce(packageFolder) { $0.appending(component: $1) }
        try FileManager.default.createDirectory(atPath: archivePath.removingLastComponent)
        Logger.debug("\(deployable.name): archive is \(archivePath)")

        if FileManager.default.fileExists(atPath: archivePath.pathString) {
            Logger.debug("\(deployable.name): file already present, won't use it")
            return archivePath
        }
        
        let temporaryFolder = try TemporaryFolder()
        
        for file in deployable.files {
            let containerPath = file.destination.removingLastComponent
            if !FileManager.default.fileExists(atPath: containerPath.pathString) {
                _ = try temporaryFolder.pathByCreatingDirectories(components: containerPath.components)
            }
            try FileManager.default.copyItem(
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
