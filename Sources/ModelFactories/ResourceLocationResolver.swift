import Extensions
import FileCache
import Foundation
import Logging
import Models
import URLResource

public final class ResourceLocationResolver {
    private let fileCache: FileCache
    private let urlResource: URLResource
    private let fileManager = FileManager()
    
    public enum ValidationError: Error {
        case unpackProcessError
        case resourceIsVoid
    }
    
    public enum Result {
        case directlyAccessibleFile(path: String)
        case contentsOfArchive(folderPath: String, filenameInArchive: String?)
        
        public var localPath: String {
            switch self {
            case .directlyAccessibleFile(let path):
                return path
            case .contentsOfArchive(let folderPath, let filenameInArchive):
                if let filenameInArchive = filenameInArchive {
                    return folderPath.appending(pathComponent: filenameInArchive)
                } else {
                    return folderPath
                }
            }
        }
    }
    
    public static let sharedResolver = ResourceLocationResolver(cachesUrl: cachesUrl())
    
    private static func cachesUrl() -> URL {
        let cacheContainer: URL
        if let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            cacheContainer = cachesUrl
        } else {
            let pathToBinaryContainer = ProcessInfo.processInfo.arguments[0].deletingLastPathComponent
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
            return Result.contentsOfArchive(folderPath: path, filenameInArchive: filenameInArchive)
        case .void:
            throw ValidationError.resourceIsVoid
        }
    }
    
    private func cachedContentsOfUrl(_ url: URL) throws -> URL {
        let handler = BlockingURLResourceHandler()
        urlResource.fetchResource(url: url, handler: handler)
        let zipUrl = try handler.wait()
        let contentsUrl = zipUrl.deletingLastPathComponent().appendingPathComponent("zip_contents", isDirectory: true)
        if !fileManager.fileExists(atPath: contentsUrl.path) {
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
