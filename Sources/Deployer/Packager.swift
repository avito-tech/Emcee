import Foundation
import ZIPFoundation
import Logging
import PathLib
import TemporaryStuff

/** Packs DeployableItem, returns URL to a single file with a package. */
public final class Packager {
    public init() {}
    
    /**
     * Packs a given DeployableItem into provided temporary folder and returns a URL to the package.
     * If the DeployableItem has been already packed, it will return URL without re-packing it.
     */
    public func preparePackage(deployable: DeployableItem, packageFolder: TemporaryFolder) throws -> AbsolutePath {
        let archivePath = deployable.name.components(separatedBy: "/").reduce(packageFolder.absolutePath) { $0.appending(component: $1) }
        try FileManager.default.createDirectory(atPath: archivePath.removingLastComponent)
        Logger.debug("\(deployable.name): archive is \(archivePath)")

        if FileManager.default.fileExists(atPath: archivePath.pathString) {
            Logger.debug("\(deployable.name): file already present, won't use it")
            return archivePath
        }
        
        guard let archive = Archive(url: archivePath.fileUrl, accessMode: .create) else {
            throw DeploymentError.unableToCreateArchive(archivePath)
        }
        for file in deployable.files {
            try pack(file: file, to: archive)
        }
        return archivePath
    }
    
    private func pack(file: DeployableFile, to archive: Archive) throws {
        let fileManager = FileManager.default

        let attributes = try fileManager.attributesOfItem(atPath: file.source.pathString)
        let resourceValues = try file.source.fileUrl.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey, .fileSizeKey])
        guard let isSymlink = resourceValues.isSymbolicLink,
            let isDirectory = resourceValues.isDirectory,
            let permissionsValue = attributes[.posixPermissions] as? NSNumber else
        {
            throw DeploymentError.unableToObtainInfoAboutFile(file)
        }
        if isDirectory {
            return
        }
        let permissions = permissionsValue.uint16Value
        
        guard let fileSize = resourceValues.fileSize else {
            throw DeploymentError.unableToObtainInfoAboutFile(file)
        }
        
        if isSymlink {
            try archive.addEntry(
                with: file.destination.pathString,
                type: .symlink,
                uncompressedSize: UInt32(fileSize),
                permissions: permissions)
            {
                _, _ in
                let linkDestination = try fileManager.destinationOfSymbolicLink(atPath: file.source.pathString)
                let linkFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: linkDestination)
                let linkLength = Int(strlen(linkFileSystemRepresentation))
                let linkBuffer = UnsafeBufferPointer(start: linkFileSystemRepresentation, count: linkLength)
                return Data(buffer: linkBuffer)
            }
        } else {
            let fileData = try Data(contentsOf: file.source.fileUrl, options: .alwaysMapped)
            try archive.addEntry(
                with: file.destination.pathString,
                type: .file,
                uncompressedSize: UInt32(fileSize),
                permissions: permissions)
            {
                position, size in fileData.subdata(in: position ..< position + size)
            }
        }
    }
}
