import Extensions
import Foundation
import UniqueIdentifierGenerator

public final class FileCache {
    private let cachesUrl: URL
    private let nameKeyer: NameKeyer
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let fileManager = FileManager()
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private struct CachedItemInfo: Codable {
        let fileName: String
        let timestamp: TimeInterval /// last time access
    }
    
    public enum Operation: Equatable {
        case copy
        case move
    }
    
    public init(
        cachesUrl: URL,
        nameHasher: NameKeyer = SHA256NameKeyer(),
        uniqueIdentifierGenerator: UniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()
    ) {
        self.cachesUrl = cachesUrl
        self.nameKeyer = nameHasher
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
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
        try safelyEvict(itemUrl: container)
    }
    
    public func store(itemAtURL itemUrl: URL, underName name: String, operation: Operation) throws {
        if contains(itemWithName: name) {
            try remove(itemWithName: name)
        }
        
        let container = try containerUrl(forItemWithName: name)
        let filename = itemUrl.lastPathComponent
        
        switch operation {
        case .copy:
            try fileManager.copyItem(
                at: itemUrl,
                to: container.appendingPathComponent(filename, isDirectory: false)
            )
        case .move:
            try fileManager.moveItem(
                at: itemUrl,
                to: container.appendingPathComponent(filename, isDirectory: false)
            )
        }
        
        let itemInfo = CachedItemInfo(fileName: filename, timestamp: Date().timeIntervalSince1970)
        try store(cachedItemInfo: itemInfo, forItemWithName: name)
    }
    
    public func url(forItemWithName name: String) throws -> URL {
        let itemInfo = try cachedItemInfo(forItemWithName: name)
        let container = try containerUrl(forItemWithName: name)
        
        let updatedItemInfo = CachedItemInfo(fileName: itemInfo.fileName, timestamp: Date().timeIntervalSince1970)
        try store(cachedItemInfo: updatedItemInfo, forItemWithName: name)
        
        return container.appendingPathComponent(itemInfo.fileName, isDirectory: false)
    }
    
    @discardableResult
    public func cleanUpItems(olderThan date: Date) throws -> [URL] {
        let allStoredCachedItemInfos = try self.allStoredCachedItemInfos()
        let evictables = allStoredCachedItemInfos.filter { (key: URL, value: CachedItemInfo) -> Bool in
            value.timestamp < date.timeIntervalSince1970
        }
        try evictables.forEach { (key: URL, value: CachedItemInfo) in
            try safelyEvict(itemUrl: key)
        }
        return [URL](evictables.keys)
    }
    
    // MARK: - Internals
    
    private func allStoredCachedItemInfos() throws -> [URL: CachedItemInfo] {
        var cachedItemInfos = [URL: CachedItemInfo]()
        
        let topLevelElements = try fileManager.contentsOfDirectory(
            at: cachesUrl,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
        )
        
        for element in topLevelElements {
            if try element.resourceValues(forKeys: [.isDirectoryKey]).isDirectory == false {
                continue
            }
            let expectedCachedItemUrl = element
                .appendingPathComponent(element.lastPathComponent, isDirectory: false)
                .appendingPathExtension("json")
            if fileManager.fileExists(atPath: expectedCachedItemUrl.path) {
                cachedItemInfos[element] = try cachedItemInfo(url: expectedCachedItemUrl)
            }
        }
        
        return cachedItemInfos
    }
    
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
        return try cachedItemInfo(url: infoFileUrl)
    }
    
    private func cachedItemInfo(url: URL) throws -> CachedItemInfo {
        let data = try Data(contentsOf: url)
        return try decoder.decode(CachedItemInfo.self, from: data)
    }
    
    private func store(cachedItemInfo: CachedItemInfo, forItemWithName name: String) throws {
        let data = try encoder.encode(cachedItemInfo)
        try data.write(to: try cachedItemInfoFileUrl(forItemWithName: name), options: .atomicWrite)
    }
    
    private func safelyEvict(itemUrl: URL) throws {
        let evictableItemUrl = itemUrl
            .deletingLastPathComponent()
            .appendingPathComponent(["evicting", uniqueIdentifierGenerator.generate(), itemUrl.lastPathComponent].joined(separator: "_"))
        try fileManager.moveItem(
            at: itemUrl,
            to: evictableItemUrl
        )
        try fileManager.removeItem(
            at: evictableItemUrl
        )
    }
}
