import Foundation
import PathLib

public final class LocalFileSystem: FileSystem {
    private let fileManager: FileManager
    
    public init(fileManager: FileManager) {
        self.fileManager = fileManager
    }
    
    public func contentEnumerator(forPath path: AbsolutePath) -> FileSystemEnumerator {
        return DefaultFileSystemEnumerator(
            fileManager: fileManager,
            path: path
        )
    }
    
    public func createDirectory(atPath path: AbsolutePath, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(
            atPath: path.pathString,
            withIntermediateDirectories: withIntermediateDirectories
        )
    }
    
    public func delete(fileAtPath path: AbsolutePath) throws {
        try fileManager.removeItem(at: path.fileUrl)
    }
    
    public func properties(forFileAtPath path: AbsolutePath) -> FilePropertiesContainer {
        return DefaultFilePropertiesContainer(path: path)
    }
    
    public var commonlyUsedPathsProvider: CommonlyUsedPathsProvider {
        return DefaultCommonlyUsedPathsProvider(fileManager: fileManager)
    }
}
