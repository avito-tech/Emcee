import DateProvider
import Extensions
import FileLock
import FileSystem
import Foundation
import Models
import PathLib
import UniqueIdentifierGenerator

public final class FileCache {
    private let cachesContainer: AbsolutePath
    private let dateProvider: DateProvider
    private let nameKeyer: NameKeyer
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let fileSystem: FileSystem
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let cacheLock: FileLock
    
    public static let evictingStatePrefix = "evicting"
    public static let defaultCacheContainerName = "ru.avito.Runner.cache"
    
    private struct CachedItemInfo: Codable {
        let fileName: String
        let timestamp: TimeInterval /// last time access
    }
    
    public enum Operation: Equatable {
        case copy
        case move
    }
    
    public static func fileCacheInDefaultLocation(
        dateProvider: DateProvider,
        fileSystem: FileSystem
    ) throws -> FileCache {
        let cacheContainer = try fileSystem.commonlyUsedPathsProvider.caches(
            inDomain: .user,
            create: true
        )
        
        return try FileCache(
            cachesContainer: cacheContainer.appending(component: FileCache.defaultCacheContainerName),
            dateProvider: dateProvider,
            fileSystem: fileSystem
        )
    }
    
    public init(
        cachesContainer: AbsolutePath,
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        nameHasher: NameKeyer = SHA256NameKeyer(),
        uniqueIdentifierGenerator: UniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()
    ) throws {
        self.cachesContainer = cachesContainer
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.nameKeyer = nameHasher
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        
        if try !fileSystem.properties(forFileAtPath: cachesContainer).exists() {
            try fileSystem.createDirectory(atPath: cachesContainer, withIntermediateDirectories: true)
        }
        
        let lockFilePath = cachesContainer.appending(component: "emcee_cache.lock")
        self.cacheLock = try FileLock(lockFilePath: lockFilePath.pathString)
    }
    
    // MARK: - Public API
    
    public func contains(itemWithName name: String) -> Bool {
        do {
            return try whileLocked {
                let filePath = try path(forItemWithName: name)
                return try fileSystem.properties(forFileAtPath: filePath).exists()
            }
        } catch {
            return false
        }
    }
    
    public func remove(itemWithName name: String) throws {
        try whileLocked {
            let container = try containerPath(forItemWithName: name)
            try safelyEvict(itemPath: container)
        }
    }
    
    public func store(itemAtPath itemPath: AbsolutePath, underName name: String, operation: Operation) throws {
        try whileLocked {
            if contains(itemWithName: name) {
                try remove(itemWithName: name)
            }
            
            let container = try containerPath(forItemWithName: name)
            let filename = itemPath.lastComponent
            
            switch operation {
            case .copy:
                try fileSystem.copy(
                    source: itemPath,
                    destination: container.appending(component: filename)
                )
            case .move:
                try fileSystem.move(
                    source: itemPath,
                    destination: container.appending(component: filename)
                )
            }
            
            let itemInfo = CachedItemInfo(fileName: filename, timestamp: dateProvider.currentDate().timeIntervalSince1970)
            try store(cachedItemInfo: itemInfo, forItemWithName: name)
        }
    }
    
    public func path(forItemWithName name: String) throws -> AbsolutePath {
        return try whileLocked {
            let itemInfo = try cachedItemInfo(forItemWithName: name)
            let container = try containerPath(forItemWithName: name)
            
            let updatedItemInfo = CachedItemInfo(fileName: itemInfo.fileName, timestamp: dateProvider.currentDate().timeIntervalSince1970)
            try store(cachedItemInfo: updatedItemInfo, forItemWithName: name)
            
            return container.appending(component: itemInfo.fileName)
        }
    }
    
    @discardableResult
    public func cleanUpItems(olderThan date: Date) throws -> [AbsolutePath] {
        return try whileLocked {
            let allStoredCachedItemInfos = try self.allStoredCachedItemInfos()
            let evictables = allStoredCachedItemInfos.filter { (key: AbsolutePath, value: CachedItemInfo) -> Bool in
                value.timestamp < date.timeIntervalSince1970
            }
            try evictables.forEach { (key: AbsolutePath, value: CachedItemInfo) in
                try safelyEvict(itemPath: key)
            }
            return [AbsolutePath](evictables.keys)
        }
    }
    
    @discardableResult
    public func cleanUpItemsToFitToSize(sizeInBytes: Int) throws -> [AbsolutePath] {
        return try whileLocked {
            let allStoredCachedItemInfos = try self.allStoredCachedItemInfos().sorted(by: { (left, right) -> Bool in
                left.value.timestamp < right.value.timestamp
            })
            
            var cachedItemInfosSizes = [(path: AbsolutePath, size: Int)]()
            try allStoredCachedItemInfos.forEach {
                var totalSize = 0
                try fileSystem.contentEnumerator(forPath: $0.key, style: .deep).each { subpath in
                    let properties = fileSystem.properties(forFileAtPath: subpath)
                    if try properties.isRegularFile() {
                        totalSize += try properties.size()
                    }
                }
                cachedItemInfosSizes.append((path: $0.key, size: totalSize))
            }
            
            let totalSizeOfCachedItems: ([(path: AbsolutePath, size: Int)]) -> Int = {
                $0.reduce(into: 0, { $0 += $1.size })
            }
            
            var evictedPaths = [AbsolutePath]()
            
            while totalSizeOfCachedItems(cachedItemInfosSizes) > sizeInBytes {
                guard !cachedItemInfosSizes.isEmpty else { break }
                let itemToEvict = cachedItemInfosSizes.removeFirst()
                try safelyEvict(itemPath: itemToEvict.path)
                evictedPaths.append(itemToEvict.path)
            }
            
            return evictedPaths
        }
    }
    
    // MARK: - Internals
    
    private func allStoredCachedItemInfos() throws -> [AbsolutePath: CachedItemInfo] {
        var cachedItemInfos = [AbsolutePath: CachedItemInfo]()
        
        let enumerator = fileSystem.contentEnumerator(forPath: cachesContainer, style: .shallow)
        try enumerator.each { element in
            if try !fileSystem.properties(forFileAtPath: element).isDirectory() {
                return
            }
            
            let expectedCachedItemPath = element.appending(component: element.lastComponent).appending(extension: "json")
            if try fileSystem.properties(forFileAtPath: expectedCachedItemPath).exists() {
                cachedItemInfos[element] = try cachedItemInfo(path: expectedCachedItemPath)
            }
        }
        
        return cachedItemInfos
    }
    
    private func containerPath(forItemWithName name: String) throws -> AbsolutePath {
        let key = try nameKeyer.key(forName: name)
        let containerPath = cachesContainer.appending(component: key)
        if try !fileSystem.properties(forFileAtPath: containerPath).exists() {
            try fileSystem.createDirectory(atPath: containerPath, withIntermediateDirectories: true)
        }
        return containerPath
    }
    
    private func cachedItemInfoPath(forItemWithName name: String) throws -> AbsolutePath {
        let key = try nameKeyer.key(forName: name)
        let container = try containerPath(forItemWithName: name)
        return container.appending(component: key).appending(extension: "json")
    }
    
    private func cachedItemInfo(forItemWithName name: String) throws -> CachedItemInfo {
        return try cachedItemInfo(path: try cachedItemInfoPath(forItemWithName: name))
    }
    
    private func cachedItemInfo(path: AbsolutePath) throws -> CachedItemInfo {
        let data = try Data(contentsOf: path.fileUrl)
        return try decoder.decode(CachedItemInfo.self, from: data)
    }
    
    private func store(cachedItemInfo: CachedItemInfo, forItemWithName name: String) throws {
        let data = try encoder.encode(cachedItemInfo)
        try data.write(to: try cachedItemInfoPath(forItemWithName: name).fileUrl, options: .atomicWrite)
    }
    
    private func safelyEvict(itemPath: AbsolutePath) throws {
        let evictableItemPath = itemPath
            .removingLastComponent
            .appending(component: [FileCache.evictingStatePrefix, uniqueIdentifierGenerator.generate(), itemPath.lastComponent].joined(separator: "_"))
        try fileSystem.move(
            source: itemPath,
            destination: evictableItemPath
        )
        try fileSystem.delete(
            fileAtPath: evictableItemPath
        )
    }
    
    public func whileLocked<T>(work: () throws -> (T)) throws -> T {
        return try cacheLock.whileLocked(work: work)
    }
}
