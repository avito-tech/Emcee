import Foundation
import PathLib

public extension FileCache {
    private func itemNameForUrl(_ url: URL) -> String {
        return url.absoluteString
    }
    
    func contains(itemForURL url: URL) -> Bool {
        return self.contains(itemWithName: itemNameForUrl(url))
    }
    
    func pathForCachedContents(ofUrl url: URL) throws -> AbsolutePath {
        return try path(forItemWithName: itemNameForUrl(url))
    }
    
    func store(contentsPath: AbsolutePath, ofUrl url: URL, operation: Operation) throws {
        try self.store(itemAtPath: contentsPath, underName: itemNameForUrl(url), operation: operation)
    }
    
    func delete(itemForURL url: URL) throws {
        try self.remove(itemWithName: itemNameForUrl(url))
    }
}
