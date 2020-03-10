import AtomicModels
import Dispatch
import Extensions
import FileCache
import Foundation
import Logging
import Models
import ProcessController
import ResourceLocation
import SynchronousWaiter
import URLResource

public final class ResourceLocationResolverImpl: ResourceLocationResolver {
    private let urlResource: URLResource
    private let cacheAccessCount = AtomicValue<Int>(0)
    private let unarchiveQueue = DispatchQueue(label: "ResourceLocationResolverImpl.unarchiveQueue")
    
    public enum ValidationError: Error, CustomStringConvertible {
        case unpackProcessError(zipPath: String, error: Error)
        
        public var description: String {
            switch self {
            case .unpackProcessError(let zipPath, let error):
                return "Unzip operation failed for archive at path \(zipPath): \(error)"
            }
        }
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
    
    private func cachedContentsOfUrl(_ url: URL) throws -> URL {
        evictOldCache()
        
        let handler = BlockingURLResourceHandler()
        urlResource.fetchResource(url: url, handler: handler)
        let zipUrl = try handler.wait(limit: 120, remoteUrl: url)
        
        let contentsUrl = zipUrl.deletingLastPathComponent().appendingPathComponent("zip_contents", isDirectory: true)
        try unarchiveQueue.sync {
            try urlResource.whileLocked {
                if !FileManager.default.fileExists(atPath: contentsUrl.path) {
                    let temporaryContentsUrl = zipUrl.deletingLastPathComponent().appendingPathComponent(
                        "zip_contents_\(UUID().uuidString)",
                        isDirectory: true
                    )
                    
                    Logger.debug("Will unzip '\(zipUrl)' into '\(temporaryContentsUrl)'")
                    
                    let processController = try DefaultProcessController(
                        subprocess: Subprocess(
                            arguments: ["/usr/bin/unzip", zipUrl.path, "-d", temporaryContentsUrl.path]
                        )
                    )
                    do {
                        try processController.startAndWaitForSuccessfulTermination()
                        Logger.debug("Moving '\(temporaryContentsUrl)' to '\(contentsUrl)'")
                        try FileManager.default.moveItem(at: temporaryContentsUrl, to: contentsUrl)
                    } catch {
                        Logger.error("Failed to unzip file: \(error)")
                        do {
                            Logger.debug("Removing downloaded file at \(url)")
                            try urlResource.deleteResource(url: url)
                            try FileManager.default.removeItem(at: temporaryContentsUrl)
                        } catch {
                            Logger.error("Failed to delete corrupted cached contents for item at url \(url)")
                        }
                        throw ValidationError.unpackProcessError(zipPath: zipUrl.path, error: error)
                    }
                }
                
                // Once we unzip the contents, we don't want to keep zip file on disk since its contents is available under zip_contents.
                // We erase it and keep empty file, to make sure cache does not refetch it when we access cached item.
                if FileManager.default.fileExists(atPath: zipUrl.path) {
                    let values = try zipUrl.resourceValues(forKeys: Set([.fileSizeKey]))
                    if values.fileSize == 0 {
                        Logger.debug("ZIP file at \(zipUrl.path) is already empty")
                    } else {
                        Logger.debug("Will replace ZIP file at \(zipUrl.path) with empty contents")
                        let handle = try FileHandle(forWritingTo: zipUrl)
                        handle.truncateFile(atOffset: 0)
                        handle.closeFile()
                        Logger.debug("ZIP file at \(zipUrl.path) now has empty contents")
                    }
                }
            }
        }
        return contentsUrl
    }
    
    private func evictOldCache() {
        let evictionRegularity = 10
        let cacheElementTimeToLive: TimeInterval = 1 * 3600
        
        cacheAccessCount.withExclusiveAccess { (counter: inout Int) in
            let evictBarrierDate = Date().addingTimeInterval(-cacheElementTimeToLive)
            
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
