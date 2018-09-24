import Foundation

public enum ResourceLocation: Hashable, CustomStringConvertible {
    case localFilePath(String)
    case remoteUrl(URL)
    
    public enum ValidationError: Error {
        case cannotCreateUrl(String)
        case fileDoesNotExist(String)
        case unsupportedUrlScheme(URL)
    }
    
    public static func from(_ string: String) throws -> ResourceLocation {
        guard var components = URLComponents(string: string) else { throw ValidationError.cannotCreateUrl(string) }
        if components.scheme == nil {
            components.scheme = "file"
        }
        guard let url = components.url else { throw ValidationError.cannotCreateUrl(string) }
        if url.isFileURL {
            return try withPathString(url.path)
        } else {
            return try withUrl(url)
        }
    }
    
    public static func from(_ strings: [String]) throws -> [ResourceLocation] {
        return try strings.map { try from($0) }
    }
    
    private static func withUrl(_ url: URL) throws -> ResourceLocation {
        return ResourceLocation.remoteUrl(url)
    }
    
    private static func withPathString(_ string: String) throws -> ResourceLocation {
        guard FileManager.default.fileExists(atPath: string) else { throw ValidationError.fileDoesNotExist(string) }
        return ResourceLocation.localFilePath(string)
    }
    
    public var hashValue: Int {
        switch self {
        case .localFilePath(let path):
            return path.hashValue
        case .remoteUrl(let url):
            return url.hashValue
        }
    }
    
    public var description: String {
        switch self {
        case .localFilePath(let path):
            return "<local path: \(path)>"
        case .remoteUrl(let url):
            return "<url: \(url)>"
        }
    }
    
    public static func == (left: ResourceLocation, right: ResourceLocation) -> Bool {
        switch (left, right) {
        case (.localFilePath(let leftPath), .localFilePath(let rightPath)):
            return leftPath == rightPath
        case (.remoteUrl(let leftUrl), .remoteUrl(let rightUrl)):
            return leftUrl == rightUrl
        default:
            return false
        }
    }
}
