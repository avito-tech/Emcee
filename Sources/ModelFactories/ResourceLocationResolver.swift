import Extensions
import FileCache
import Foundation
import Logging
import Models
import ProcessController
import URLResource

public final class ResourceLocationResolver {
    private let fileCache: FileCache
    private let urlResource: URLResource
    private let fileManager = FileManager()
    
    public enum ValidationError: Error {
        case binaryNotFoundAtPath(String)
        case unpackProcessError
    }
    
    public enum Result {
        case directlyAccessibleFile(path: String)
        case contentsOfArchive(folderPath: String)
        
        public func with(archivedFile: String) -> String {
            switch self {
            case .directlyAccessibleFile(let path):
                return path
            case .contentsOfArchive(let folderPath):
                return folderPath.appending(pathComponent: archivedFile)
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
            return Result.contentsOfArchive(folderPath: path)
        }
    }
    
    private func cachedContentsOfUrl(_ url: URL) throws -> URL {
        let handler = BlockingURLResourceHandler()
        urlResource.fetchResource(url: url, handler: handler)
        let zipUrl = try handler.wait()
        let contentsUrl = zipUrl.deletingLastPathComponent().appendingPathComponent("zip_contents", isDirectory: true)
        if !fileManager.fileExists(atPath: contentsUrl.path) {
            log("Will unzip '\(zipUrl)' into '\(contentsUrl)'")
            let controller = ProcessController(
                subprocess: Subprocess(arguments: ["/usr/bin/unzip", zipUrl.path, "-d", contentsUrl.path]),
                maximumAllowedSilenceDuration: nil)
            controller.startAndListenUntilProcessDies()
            guard controller.terminationStatus() == 0 else { throw ValidationError.unpackProcessError }
        }
        return contentsUrl
    }
}
