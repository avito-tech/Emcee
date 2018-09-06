import Extensions
import Foundation

public final class FileCache {
    private let cachesUrl: URL
    private let nameKeyer: NameKeyer
    private let fileManager = FileManager()
    
    public init(cachesUrl: URL, nameHasher: NameKeyer = SHA256NameKeyer()) {
        self.cachesUrl = cachesUrl
        self.nameKeyer = nameHasher
    }
    
    // MARK: - Public API
    
    public func contains(itemWithName name: String) -> Bool {
        do {
            let fileUrl = try url(forItemWithName: name)
            return fileManager.fileExists(atPath: fileUrl.path)
        } catch {
            return false
        }
    }
    
    public func remove(itemWithName name: String) throws {
        let container = try containerUrl(forItemWithName: name)
        try fileManager.removeItem(at: container)
    }
    
    public func store(itemAtURL itemUrl: URL, underName name: String) throws {
        if contains(itemWithName: name) {
            try remove(itemWithName: name)
        }
        
        let container = try containerUrl(forItemWithName: name)
        let filename = itemUrl.lastPathComponent
        try fileManager.copyItem(
            at: itemUrl,
            to: container.appendingPathComponent(filename, isDirectory: false))
        
        let itemInfo = CachedItemInfo(fileName: filename, timestamp: Date().timeIntervalSince1970)
        let data = try encoder.encode(itemInfo)
        try data.write(to: try cachedItemInfoFileUrl(forItemWithName: name), options: .atomicWrite)
    }
    
    public func url(forItemWithName name: String) throws -> URL {
        let itemInfo = try cachedItemInfo(forItemWithName: name)
        let container = try containerUrl(forItemWithName: name)
        return container.appendingPathComponent(itemInfo.fileName, isDirectory: false)
    }
    
    // MARK: - Internals
    
    private struct CachedItemInfo: Codable {
        let fileName: String
        let timestamp: TimeInterval
    }
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private func containerUrl(forItemWithName name: String) throws -> URL {
        let key = try nameKeyer.key(forName: name)
        let containerUrl = cachesUrl.appendingPathComponent(key, isDirectory: true)
        if !fileManager.fileExists(atPath: containerUrl.path) {
            try fileManager.createDirectory(at: containerUrl, withIntermediateDirectories: true)
        }
        return containerUrl
    }
    
    private func cachedItemInfoFileUrl(forItemWithName name: String) throws -> URL {
        let key = try nameKeyer.key(forName: name)
        let container = try containerUrl(forItemWithName: name)
        return container.appendingPathComponent(key, isDirectory: false).appendingPathExtension("json")
    }
    
    private func cachedItemInfo(forItemWithName name: String) throws -> CachedItemInfo {
        let infoFileUrl = try cachedItemInfoFileUrl(forItemWithName: name)
        let data = try Data(contentsOf: infoFileUrl)
        return try decoder.decode(CachedItemInfo.self, from: data)
    }
}
