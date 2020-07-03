import Foundation
import PathLib

public final class LocalFileSystem: FileSystem {
    private let fileManager = FileManager()
    
    private enum LocalFileSystemError: Error {
        case failedToCreateFile(AbsolutePath)
    }
    
    public init() {}
    
    public func contentEnumerator(forPath path: AbsolutePath, style: ContentEnumerationStyle) -> FileSystemEnumerator {
        switch style {
        case .deep:
            return DeepFileSystemEnumerator(fileManager: fileManager, path: path)
        case .shallow:
            return ShallowFileSystemEnumerator(fileManager: fileManager, path: path)
        }
        
    }
    
    public func createDirectory(atPath path: AbsolutePath, withIntermediateDirectories: Bool) throws {
        try fileManager.createDirectory(
            atPath: path.pathString,
            withIntermediateDirectories: withIntermediateDirectories
        )
    }
    
    public func createFile(atPath path: AbsolutePath, data: Data?) throws {
        if !fileManager.createFile(atPath: path.pathString, contents: data) {
            throw LocalFileSystemError.failedToCreateFile(path)
        }
    }
    
    public func copy(source: AbsolutePath, destination: AbsolutePath) throws {
        try fileManager.copyItem(at: source.fileUrl, to: destination.fileUrl)
    }
    
    public func move(source: AbsolutePath, destination: AbsolutePath) throws {
        try fileManager.moveItem(at: source.fileUrl, to: destination.fileUrl)
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
