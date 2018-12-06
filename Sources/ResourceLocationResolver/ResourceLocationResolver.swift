import Dispatch
import Extensions
import FileCache
import Foundation
import Logging
import Models
import URLResource

public final class ResourceLocationResolver {
    private let urlResource: URLResource
    private let cacheAccessCount = AtomicValue<Int>(0)
    private let unarchiveQueue = DispatchQueue(label: "ru.avito.emcee.ResourceLocationResolver.unarchiveQueue")
    
    public enum ValidationError: String, Error, CustomStringConvertible {
        case unpackProcessError = "Unzip operation failed."
        
        public var description: String {
            return self.rawValue
        }
    }
    
    private static func cachesUrl() -> URL {
        let cacheContainer: URL
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            cacheContainer = cachesUrl
        } else {
            let pathToBinaryContainer = ProcessInfo.processInfo.executablePath.deletingLastPathComponent
            cacheContainer = URL(fileURLWithPath: pathToBinaryContainer)
        }
        return cacheContainer.appendingPathComponent("ru.avito.Runner.cache", isDirectory: true)
    }
    
    public convenience init() {
        let fileCache = FileCache(cachesUrl: ResourceLocationResolver.cachesUrl())
        let urlResource = URLResource(fileCache: fileCache, urlSession: URLSession.shared)
        self.init(urlResource: urlResource)
    }
    
    public init(urlResource: URLResource) {
        self.urlResource = urlResource
    }
    
    public func resolvePath(resourceLocation: ResourceLocation) throws -> ResolvingResult {
        switch resourceLocation {
        case .localFilePath(let path):
            return .directlyAccessibleFile(path: path)
        case .remoteUrl(let url):
            let path = try cachedContentsOfUrl(url).path
            let filenameInArchive = url.fragment
            return .contentsOfArchive(containerPath: path, filenameInArchive: filenameInArchive)
        }
    }
    
    public func resolvable(resourceLocation: ResourceLocation) -> ResolvableResourceLocation {
        return ResolvableResourceLocationImpl(resourceLocation: resourceLocation, resolver: self)
    }
    
    public func resolvable(withRepresentable representable: RepresentableByResourceLocation) -> ResolvableResourceLocation {
        return ResolvableResourceLocationImpl(withRepresentable: representable, resolver: self)
    }
    
    private func cachedContentsOfUrl(_ url: URL) throws -> URL {
        evictOldCache()
        
        let handler = BlockingURLResourceHandler()
        urlResource.fetchResource(url: url, handler: handler)
        let zipUrl = try handler.wait()
        
        let contentsUrl = zipUrl.deletingLastPathComponent().appendingPathComponent("zip_contents", isDirectory: true)
        try unarchiveQueue.sync {
            if !FileManager.default.fileExists(atPath: contentsUrl.path) {
                log("Will unzip '\(zipUrl)' into '\(contentsUrl)'")
                let process = Process.launchedProcess(
                    launchPath: "/usr/bin/unzip",
                    arguments: ["-qq", zipUrl.path, "-d", contentsUrl.path]
                )
                process.waitUntilExit()
                if process.terminationStatus != 0 {
                    throw ValidationError.unpackProcessError
                }
            }
        }
        return contentsUrl
    }
    
    private func evictOldCache() {
        // let's evict old cached data from time to time, on each N-th cache access
        let evictionRegularity = 10
        let secondsInDay: TimeInterval = 86400
        let days: TimeInterval = 1
        
        cacheAccessCount.withExclusiveAccess { (counter: inout Int) in
            let evictBarrierDate = Date().addingTimeInterval(-days * secondsInDay)
            
            if counter % evictionRegularity == 0 {
                counter = 1
                let evictedEntryURLs = (try? urlResource.evictResources(olderThan: evictBarrierDate)) ?? []
                log("Evicted \(evictedEntryURLs.count) cached items older than: \(evictBarrierDate)")
                for url in evictedEntryURLs {
                    log("-- evicted \(url)")
                }
            } else {
                counter = counter + 1
            }
        }
    }
}
