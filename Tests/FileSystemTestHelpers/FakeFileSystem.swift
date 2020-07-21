import FileSystem
import Foundation
import PathLib

public class FakeFileSystem: FileSystem {
    public init(rootPath: AbsolutePath) {
        self.fakeCommonlyUsedPathsProvider = FakeCommonlyUsedPathsProvider(
            applicationsProvider: { _ in rootPath.appending(components: ["Applications"]) },
            cachesProvider: { _ in rootPath.appending(components: ["Library", "Caches"]) },
            libraryProvider: { _ in rootPath.appending(component: "Library") }
        )
    }
    
    public var fakeCommonlyUsedPathsProvider: FakeCommonlyUsedPathsProvider
    public var commonlyUsedPathsProvider: CommonlyUsedPathsProvider { fakeCommonlyUsedPathsProvider }
    
    public var fakeContentEnumerator: ((path: AbsolutePath, style: ContentEnumerationStyle)) -> FileSystemEnumerator = { args in
        FakeFileSystemEnumerator(path: args.path)
    }
    
    public func contentEnumerator(forPath path: AbsolutePath, style: ContentEnumerationStyle) -> FileSystemEnumerator {
        fakeContentEnumerator((path: path, style: style))
    }
    
    public func createDirectory(atPath: AbsolutePath, withIntermediateDirectories: Bool) throws {
        
    }
    
    public func createFile(atPath: AbsolutePath, data: Data?) throws {
        
    }
    
    public func copy(source: AbsolutePath, destination: AbsolutePath) throws {
        
    }
    
    public func move(source: AbsolutePath, destination: AbsolutePath) throws {
        
    }
    
    public func delete(fileAtPath: AbsolutePath) throws {
        
    }
    
    public var propertiesProvider: (AbsolutePath) -> FilePropertiesContainer = { FakeFilePropertiesContainer(path: $0) }
    public func properties(forFileAtPath path: AbsolutePath) -> FilePropertiesContainer {
        propertiesProvider(path)
    }
}
