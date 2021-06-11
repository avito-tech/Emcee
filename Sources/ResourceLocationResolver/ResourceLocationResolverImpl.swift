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
    private let logger: ContextualLogger
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
        logger: ContextualLogger,
        urlResource: URLResource,
        cacheElementTimeToLive: TimeInterval,
        maximumCacheSize: Int,
        processControllerProvider: ProcessControllerProvider
    ) {
        self.fileSystem = fileSystem
        self.logger = logger
        self.urlResource = urlResource
        self.cacheElementTimeToLive = cacheElementTimeToLive
        self.maximumCacheSize = maximumCacheSize
        self.processControllerProvider = processControllerProvider
    }
    
    public func resolvePath(resourceLocation: ResourceLocation) throws -> ResolvingResult {
        switch resourceLocation {
        case .localFilePath(let path):
            return .directlyAccessibleFile(path: AbsolutePath(path))
        case .remoteUrl(let url, let headers):
            let path = try cachedContentsOfUrl(url, headers)
            let filenameInArchive = url.fragment
            return .contentsOfArchive(containerPath: path, filenameInArchive: filenameInArchive)
        }
    }
    
    private func cachedContentsOfUrl(_ url: URL, _ headers: [String: String]?) throws -> AbsolutePath {
        evictOldCache()
        
        let handler = BlockingURLResourceHandler()
        urlResource.fetchResource(url: url, handler: handler, headers: headers)
        let zipFilePath = try handler.wait(limit: 120, remoteUrl: url)
        
        let contentsPath = zipFilePath.removingLastComponent.appending(component: "zip_contents")
        try unarchiveQueue.sync {
            try urlResource.whileLocked {
                if !fileSystem.properties(forFileAtPath: contentsPath).exists() {
                    let temporaryContentsPath = zipFilePath.removingLastComponent.appending(
                        component: "zip_contents_\(UUID().uuidString)"
                    )
                    
                    logger.debug("Will unzip \(zipFilePath) into \(temporaryContentsPath)")
                    
                    let processController = try processControllerProvider.createProcessController(
                        subprocess: Subprocess(
                            arguments: ["/usr/bin/unzip", zipFilePath, "-d", temporaryContentsPath]
                        )
                    )
                    do {
                        try processController.startAndWaitForSuccessfulTermination()
                        logger.debug("Moving \(temporaryContentsPath) to \(contentsPath)")
                        try fileSystem.move(source: temporaryContentsPath, destination: contentsPath)
                    } catch {
                        logger.error("Failed to unzip file: \(error)")
                        do {
                            logger.debug("Removing downloaded file at \(url)")
                            try urlResource.deleteResource(url: url)
                            try fileSystem.delete(fileAtPath: temporaryContentsPath)
                        } catch {
                            logger.error("Failed to delete corrupted cached contents for item at url \(url)")
                        }
                        throw ValidationError.unpackProcessError(zipPath: zipFilePath, error: error)
                    }
                }
                
                // Once we unzip the contents, we don't want to keep zip file on disk since its contents is available under zip_contents.
                // We erase it and keep empty file, to make sure cache does not refetch it when we access cached item.
                if let zipFileSize = try? fileSystem.properties(forFileAtPath: zipFilePath).size(), zipFileSize != 0 {
                    logger.debug("Will replace ZIP file at \(zipFilePath) with empty contents")
                    let handle = try FileHandle(forWritingTo: zipFilePath.fileUrl)
                    handle.truncateFile(atOffset: 0)
                    handle.closeFile()
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
                logger.debug("Evicted \(evictedEntryPaths.count) cached items older than: \(LoggableDate(evictBarrierDate))")
                evictedEntryPaths = (try? urlResource.evictResources(toFitSize: maximumCacheSize)) ?? []
                logger.debug("Evicted \(evictedEntryPaths.count) cached items to limit cache size to \(maximumCacheSize) bytes")
            } else {
                counter = counter + 1
            }
        }
    }
}
