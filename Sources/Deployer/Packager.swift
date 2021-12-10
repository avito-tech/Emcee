import Foundation
import FileSystem
import PathLib
import Zip

/** Packs DeployableItem, returns URL to a single file with a package. */
public final class Packager {
    private let fileSystem: FileSystem
    private let zipCompressor: ZipCompressor
    
    public init(
        fileSystem: FileSystem,
        zipCompressor: ZipCompressor
    ) {
        self.fileSystem = fileSystem
        self.zipCompressor = zipCompressor
    }
    
    /**
     * Packs a given DeployableItem into provided temporary folder and returns a URL to the package.
     * If the DeployableItem has been already packed, it will return URL without re-packing it.
     */
    public func preparePackage(deployable: DeployableItem, packageFolder: AbsolutePath) throws -> AbsolutePath {
        let archivePath = deployable.name.components(separatedBy: "/")
            .reduce(packageFolder) { $0.appending($1) }

        try fileSystem.createDirectory(
            path: archivePath.removingLastComponent,
            withIntermediateDirectories: true,
            ignoreExisting: true
        )
        
        if fileSystem.exists(path: archivePath) {
            return archivePath
        }
        
        for file in deployable.files {
            try fileSystem.copy(
                source: file.source,
                destination: packageFolder.appending(relativePath: file.destination),
                overwrite: false,
                ensureDirectoryExists: true
            )
        }
        
        return try zipCompressor.createArchive(
            archivePath: archivePath,
            workingDirectory: packageFolder,
            contentsToCompress: "."
        )
    }
}
