import Foundation

public extension FileCache {
    private func itemNameForUrl(_ url: URL) -> String {
        return url.absoluteString
    }
    
    func contains(itemForURL url: URL) -> Bool {
        return self.contains(itemWithName: itemNameForUrl(url))
    }
    
    func urlForCachedContents(ofUrl url: URL) throws -> URL {
        return try self.url(forItemWithName: itemNameForUrl(url))
    }
    
    func store(contentsUrl: URL, ofUrl url: URL, operation: Operation) throws {
        try self.store(itemAtURL: contentsUrl, underName: itemNameForUrl(url), operation: operation)
    }
}
