import Extensions
import FileCache
import Foundation
import Logging
import Models
import URLResource

public final class ResourceLocationResolver {
    private let fileCache: FileCache
    private let urlResource: URLResource
    
    public enum ValidationError: String, Error, CustomStringConvertible {
        case unpackProcessError = "Unzip operation failed."
        
        public var description: String {
            return self.rawValue
        }
    }
    
    /// A result of materializing `ResourceLocation` object.
    public enum Result {
        /// A given `ResourceLocation` object is pointing to the local file on disk
        case directlyAccessibleFile(path: String)
        
        /// A given `ResourceLocation` object is pointing to archive that has been fetched and extracted.
        /// If URL had a fragment, then `filenameInArchive` will be non-nil.
        case contentsOfArchive(containerPath: String, filenameInArchive: String?)
    }
    
    public static let sharedResolver = ResourceLocationResolver(cachesUrl: cachesUrl())
    
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
    
    private init(cachesUrl: URL) {
        self.fileCache = FileCache(cachesUrl: cachesUrl)
        self.urlResource = URLResource(fileCache: fileCache, urlSession: URLSession.shared)
    }
    
    public func resolvePath(resourceLocation: ResourceLocation) throws -> Result {
        switch resourceLocation {
        case .localFilePath(let path):
            return Result.directlyAccessibleFile(path: path)
        case .remoteUrl(let url):
            let path = try cachedContentsOfUrl(url).path
            let filenameInArchive = url.fragment
            return Result.contentsOfArchive(containerPath: path, filenameInArchive: filenameInArchive)
        }
    }
    
    private func cachedContentsOfUrl(_ url: URL) throws -> URL {
        let handler = BlockingURLResourceHandler()
        urlResource.fetchResource(url: url, handler: handler)
        let zipUrl = try handler.wait()
        let contentsUrl = zipUrl.deletingLastPathComponent().appendingPathComponent("zip_contents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: contentsUrl.path) {
            log("Will unzip '\(zipUrl)' into '\(contentsUrl)'")
            let process = Process.launchedProcess(
                launchPath: "/usr/bin/unzip",
                arguments: [zipUrl.path, "-d", contentsUrl.path])
            process.waitUntilExit()
            if process.terminationStatus != 0 {
                throw ValidationError.unpackProcessError
            }
        }
        return contentsUrl
    }
}
