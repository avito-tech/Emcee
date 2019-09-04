import AtomicModels
import Dispatch
import Extensions
import FileCache
import Foundation
import Logging
import Models
import ProcessController
import URLResource

public final class ResourceLocationResolver {
    private let urlResource: URLResource
    private let cacheAccessCount = AtomicValue<Int>(0)
    private let unarchiveQueue = DispatchQueue(label: "ru.avito.emcee.ResourceLocationResolver.unarchiveQueue")
    
    public enum ValidationError: Error, CustomStringConvertible {
        case unpackProcessError(zipPath: String)
        
        public var description: String {
            switch self {
            case .unpackProcessError(let zipPath):
                return "Unzip operation failed for archive at path: \(zipPath)"
            }
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
    
    public convenience init() throws {
        let fileCache = try FileCache(cachesUrl: ResourceLocationResolver.cachesUrl())
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
                Logger.debug("Will unzip '\(zipUrl)' into '\(contentsUrl)'")
                
                let processController = try ProcessController(
                    subprocess: Subprocess(
                        arguments: ["/usr/bin/unzip", "-qq", zipUrl.path, "-d", contentsUrl.path]
                    )
                )
                processController.startAndListenUntilProcessDies()
                guard processController.processStatus() == .terminated(exitCode: 0) else {
                    do {
                        try urlResource.deleteResource(url: url)
                    } catch {
                        Logger.error("Failed to delete corrupted cached contents for item at url \(url)")
                    }
                    throw ValidationError.unpackProcessError(zipPath: zipUrl.path)
                }
            }

            // Once we unzip the contents, we don't want to keep zip file on disk since its contents is available under zip_contents.
            // We erase it and keep empty file, to make sure cache does not refetch it when we access cached item.
            if FileManager.default.fileExists(atPath: zipUrl.path) {
                Logger.debug("Will replace ZIP file at: \(zipUrl.path) with empty contents")
                let handle = try FileHandle(forWritingTo: zipUrl)
                handle.truncateFile(atOffset: 0)
                handle.closeFile()
            }
        }
        return contentsUrl
    }
    
    private func evictOldCache() {
        // let's evict old cached data from time to time, on each N-th cache access
        let evictionRegularity = 10
        let secondsInDay: TimeInterval = 86400
        let days: TimeInterval = 0.25
        
        cacheAccessCount.withExclusiveAccess { (counter: inout Int) in
            let evictBarrierDate = Date().addingTimeInterval(-days * secondsInDay)
            
            if counter % evictionRegularity == 0 {
                counter = 1
                let evictedEntryURLs = (try? urlResource.evictResources(olderThan: evictBarrierDate)) ?? []
                let formattedEvictBarrierDate = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: evictBarrierDate)
                Logger.debug("Evicted \(evictedEntryURLs.count) cached items older than: \(formattedEvictBarrierDate)")
                for url in evictedEntryURLs {
                    Logger.debug("-- evicted \(url)")
                }
            } else {
                counter = counter + 1
            }
        }
    }
}
