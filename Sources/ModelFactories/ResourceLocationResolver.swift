import Extensions
import FileCache
import Foundation
import Models
import URLResource
import ZIPFoundation

public final class ResourceLocationResolver {
    private let fileCache: FileCache
    private let urlResource: URLResource
    
    public enum PathValidationError: Error {
        case binaryNotFoundAtPath(String)
    }
    
    public static let sharedResolver: ResourceLocationResolver = {
        guard let cachesUrl = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            let pathToBinaryContainer = ProcessInfo.processInfo.arguments[0].deletingLastPathComponent
            return ResourceLocationResolver(cachesUrl: URL(fileURLWithPath: pathToBinaryContainer))
        }
        return ResourceLocationResolver(cachesUrl: cachesUrl)
    }()
    
    private init(cachesUrl: URL) {
        self.fileCache = FileCache(cachesUrl: cachesUrl)
        self.urlResource = URLResource(fileCache: fileCache, urlSession: URLSession.shared)
    }
    
    public func resolvePathToBinary(resourceLocation: ResourceLocation, binaryName: String) throws -> String {
        let resourceUrl = try resolvePath(resourceLocation: resourceLocation)
        let path = resourceUrl.lastPathComponent == binaryName
            ? resourceUrl.path
            : resourceUrl.appendingPathComponent(binaryName, isDirectory: false).path
        guard FileManager.default.fileExists(atPath: path) else { throw PathValidationError.binaryNotFoundAtPath(path) }
        return path
    }
    
    public func resolvePath(resourceLocation: ResourceLocation) throws -> URL {
        switch resourceLocation {
        case .localFilePath(let path):
            return URL(fileURLWithPath: path)
        case .remoteUrl(let url):
            return try cachedContentsOfUrl(url)
        }
    }
    
    private func cachedContentsOfUrl(_ url: URL) throws -> URL {
        let handler = BlockingHandler()
        urlResource.fetchResource(url: url, handler: handler)
        let zipUrl = try handler.wait()
        let contentsUrl = zipUrl.appendingPathComponent("zip_contents", isDirectory: true)
        if !FileManager.default.fileExists(atPath: contentsUrl.path) {
            try FileManager.default.unzipItem(at: zipUrl, to: contentsUrl)
        }
        return contentsUrl
    }
}
