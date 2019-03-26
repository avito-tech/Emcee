import Foundation
import Basic
import ZIPFoundation
import Logging

/** Packs DeployableItem, returns URL to a single file with a package. */
public final class Packager {
    public init() {}
    
    /**
     * Packs a given DeployableItem into provided TemporaryDirectory and returns a URL to the package.
     * If the DeployableItem has been already packed, it will return URL without re-packing it.
     */
    public func preparePackage(deployable: DeployableItem, packageFolder: TemporaryDirectory) throws -> URL {
        let path = deployable.name.components(separatedBy: "/").reduce(packageFolder.path) { $0.appending(component: $1) }
        try FileManager.default.createDirectory(atPath: path.parentDirectory.pathString, withIntermediateDirectories: true, attributes: nil)
        let archiveUrl = URL(fileURLWithPath: path.pathString)
        Logger.debug("\(deployable.name): archive url is \(archiveUrl.path)")

        if FileManager.default.fileExists(atPath: archiveUrl.path) {
            Logger.debug("\(deployable.name): file already present, won't use it")
            return archiveUrl
        }
        
        guard let archive = Archive(url: archiveUrl, accessMode: .create) else {
            throw DeploymentError.unableToCreateArchive(archiveUrl)
        }
        for file in deployable.files {
            try pack(file: file, to: archive)
        }
        return archiveUrl
    }
    
    private func pack(file: DeployableFile, to archive: Archive) throws {
        let fileManager = FileManager.default
        let sourceUrl = URL(fileURLWithPath: file.source)
        let attributes = try fileManager.attributesOfItem(atPath: sourceUrl.path)
        let resourceValues = try sourceUrl.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey, .fileSizeKey])
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
                with: file.destination,
                type: .symlink,
                uncompressedSize: UInt32(fileSize),
                permissions: permissions)
            {
                _, _ in
                let linkDestination = try fileManager.destinationOfSymbolicLink(atPath: file.source)
                let linkFileSystemRepresentation = fileManager.fileSystemRepresentation(withPath: linkDestination)
                let linkLength = Int(strlen(linkFileSystemRepresentation))
                let linkBuffer = UnsafeBufferPointer(start: linkFileSystemRepresentation, count: linkLength)
                return Data(buffer: linkBuffer)
            }
        } else {
            let fileData = try Data(contentsOf: sourceUrl, options: .alwaysMapped)
            try archive.addEntry(
                with: file.destination,
                type: .file,
                uncompressedSize: UInt32(fileSize),
                permissions: permissions)
            {
                position, size in fileData.subdata(in: position ..< position + size)
            }
        }
    }
}
