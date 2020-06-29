import Foundation
import PathLib

public final class DeepFileSystemEnumerator: FileSystemEnumerator {
    private let path: AbsolutePath
    private let fileManager: FileManager
    
    public enum EnumerationError: Error {
        case enumeratorFailure
    }
    
    public init(
        fileManager: FileManager,
        path: AbsolutePath
    ) {
        self.fileManager = fileManager
        self.path = path
    }
    
    public func each(iterator: (AbsolutePath) throws -> ()) throws {
        guard let enumerator = fileManager.enumerator(at: path.fileUrl, includingPropertiesForKeys: nil) else {
            throw EnumerationError.enumeratorFailure
        }
        
        for case let fileURL as URL in enumerator {
            let absolutePath = AbsolutePath(fileURL)
            try iterator(absolutePath)
        }
    }
}
