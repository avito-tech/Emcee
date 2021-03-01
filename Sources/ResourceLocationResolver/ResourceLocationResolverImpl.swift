import AtomicModels
import Dispatch
import FileCache
import FileSystem
import Foundation
import EmceeLogging
import PathLib
import ProcessController
import ResourceLocation
import SynchronousWaiter
import URLResource

public final class ResourceLocationResolverImpl: ResourceLocationResolver {
    private let fileSystem: FileSystem
    private let urlResource: URLResource
    private let cacheAccessCount = AtomicValue<Int>(0)
    private let cacheElementTimeToLive: TimeInterval
    private let maximumCacheSize: Int
    private let processControllerProvider: ProcessControllerProvider
    private let unarchiveQueue = DispatchQueue(label: "ResourceLocationResolverImpl.unarchiveQueue")
    
    public enum ValidationError: Error, CustomStringConvertible {
        case unpackProcessError(zipPath: AbsolutePath, error: Error)
        
        public var description: String {
            switch self {
            case .unpackProcessError(let zipPath, let error):
                return "Unzip operation failed for archive at path \(zipPath): \(error)"
            }
        }
    }
    
    public init(
        fileSystem: FileSystem,
        urlResource: URLResource,
        cacheElementTimeToLive: TimeInterval,
        maximumCacheSize: Int,
        processControllerProvider: ProcessControllerProvider
    ) {
        self.fileSystem = fileSystem
        self.urlResource = urlResource
        self.cacheElementTimeToLive = cacheElementTimeToLive
        self.maximumCacheSize = maximumCacheSize
        self.processControllerProvider = processControllerProvider
    }
    
    public func resolvePath(resourceLocation: ResourceLocation) throws -> ResolvingResult {
        switch resourceLocation {
        case .localFilePath(let path):
            return .directlyAccessibleFile(path: AbsolutePath(path))
        case .remoteUrl(let url):
            let path = try cachedContentsOfUrl(url)
            let filenameInArchive = url.fragment
            return .contentsOfArchive(containerPath: path, filenameInArchive: filenameInArchive)
        }
    }
    
    private func cachedContentsOfUrl(_ url: URL) throws -> AbsolutePath {
        evictOldCache()
        
        let handler = BlockingURLResourceHandler()
        urlResource.fetchResource(url: url, handler: handler)
        let zipFilePath = try handler.wait(limit: 120, remoteUrl: url)
        
        let contentsPath = zipFilePath.removingLastComponent.appending(component: "zip_contents")
        try unarchiveQueue.sync {
            try urlResource.whileLocked {
                if !fileSystem.properties(forFileAtPath: contentsPath).exists() {
                    let temporaryContentsPath = zipFilePath.removingLastComponent.appending(
                        component: "zip_contents_\(UUID().uuidString)"
                    )
                    
                    Logger.debug("Will unzip '\(zipFilePath)' into '\(temporaryContentsPath)'")
                    
                    let processController = try processControllerProvider.createProcessController(
                        subprocess: Subprocess(
                            arguments: ["/usr/bin/unzip", zipFilePath, "-d", temporaryContentsPath]
                        )
                    )
                    do {
                        try processController.startAndWaitForSuccessfulTermination()
                        Logger.debug("Moving '\(temporaryContentsPath)' to '\(contentsPath)'")
                        try fileSystem.move(source: temporaryContentsPath, destination: contentsPath)
                    } catch {
                        Logger.error("Failed to unzip file: \(error)")
                        do {
                            Logger.debug("Removing downloaded file at \(url)")
                            try urlResource.deleteResource(url: url)
                            try fileSystem.delete(fileAtPath: temporaryContentsPath)
                        } catch {
                            Logger.error("Failed to delete corrupted cached contents for item at url \(url)")
                        }
                        throw ValidationError.unpackProcessError(zipPath: zipFilePath, error: error)
                    }
                }
                
                // Once we unzip the contents, we don't want to keep zip file on disk since its contents is available under zip_contents.
                // We erase it and keep empty file, to make sure cache does not refetch it when we access cached item.
                if let zipFileSize = try? fileSystem.properties(forFileAtPath: zipFilePath).size(), zipFileSize != 0 {
                    Logger.debug("Will replace ZIP file at \(zipFilePath) with empty contents")
                    let handle = try FileHandle(forWritingTo: zipFilePath.fileUrl)
                    handle.truncateFile(atOffset: 0)
                    handle.closeFile()
                    Logger.debug("ZIP file at \(zipFilePath) now has empty contents")
                }
            }
        }
        return contentsPath
    }
    
    private func evictOldCache() {
        let evictionRegularity = 10
        
        cacheAccessCount.withExclusiveAccess { (counter: inout Int) in
            let evictBarrierDate = Date().addingTimeInterval(-cacheElementTimeToLive)
            
            if counter % evictionRegularity == 0 {
                counter = 1
                var evictedEntryPaths = (try? urlResource.evictResources(olderThan: evictBarrierDate)) ?? []
                Logger.debug("Evicted \(evictedEntryPaths.count) cached items older than: \(LoggableDate(evictBarrierDate))")
                for path in evictedEntryPaths {
                    Logger.debug("-- evicted \(path)")
                }
                
                evictedEntryPaths = (try? urlResource.evictResources(toFitSize: maximumCacheSize)) ?? []
                Logger.debug("Evicted \(evictedEntryPaths.count) cached items to limit cache size to \(maximumCacheSize) bytes")
                for path in evictedEntryPaths {
                    Logger.debug("-- evicted \(path)")
                }
            } else {
                counter = counter + 1
            }
        }
    }
}
