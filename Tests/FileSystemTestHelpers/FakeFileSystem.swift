import FileSystem
import Foundation
import PathLib

public class FakeFileSystem: FileSystem {
    public init(rootPath: AbsolutePath) {
        self.fakeCommonlyUsedPathsProvider = FakeCommonlyUsedPathsProvider(
            cachesProvider: { _ in rootPath.appending(components: ["Library", "Caches"]) },
            libraryProvider: { _ in rootPath.appending(component: "Library") }
        )
    }
    
    public var fakeCommonlyUsedPathsProvider: FakeCommonlyUsedPathsProvider
    public var commonlyUsedPathsProvider: CommonlyUsedPathsProvider { fakeCommonlyUsedPathsProvider }
    
    public func contentEnumerator(forPath path: AbsolutePath) -> FileSystemEnumerator {
        return FakeFileSystemEnumerator(path: path)
    }
    
    public func createDirectory(atPath: AbsolutePath, withIntermediateDirectories: Bool) throws {
        
    }
    
    public func delete(fileAtPath: AbsolutePath) throws {
        
    }
    
    public var propertiesProvider: (AbsolutePath) -> FilePropertiesContainer = { FakeFilePropertiesContainer(path: $0) }
    public func properties(forFileAtPath path: AbsolutePath) -> FilePropertiesContainer {
        propertiesProvider(path)
    }
}
