import FileSystem
import Foundation
import PathLib

public class FakeFileSystemEnumerator: FileSystemEnumerator {
    public let path: AbsolutePath
    public var items = [AbsolutePath]()
    
    public init(path: AbsolutePath) {
        self.path = path
    }
    
    public func each(iterator: (AbsolutePath) throws -> ()) throws {
        try items.forEach(iterator)
    }
}
