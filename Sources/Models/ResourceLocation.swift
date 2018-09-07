import Foundation

public enum ResourceLocation {
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
    
    private static func withUrl(_ url: URL) throws -> ResourceLocation {
        return ResourceLocation.remoteUrl(url)
    }
    
    private static func withPathString(_ string: String) throws -> ResourceLocation {
        guard FileManager.default.fileExists(atPath: string) else { throw ValidationError.fileDoesNotExist(string) }
        return ResourceLocation.localFilePath(string)
    }
}
