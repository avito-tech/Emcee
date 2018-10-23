import Foundation

/// A location of the resource.
public enum ResourceLocation: Hashable, CustomStringConvertible, Codable {
    /// direct path to the file on disk
    case localFilePath(String)
    
    /// URL to archive that should be extracted in order to get the file.
    /// Filename in this case can be specified by fragment:
    /// http://example.com/file.zip#actualFileInsideZip
    case remoteUrl(URL)
    
    public enum ValidationError: Error, CustomStringConvertible {
        case cannotCreateUrl(String)
        case fileDoesNotExist(String)
        
        public var description: String {
            switch self {
            case .cannotCreateUrl(let string):
                return "Attempt to create a URL from string '\(string)' failed"
            case .fileDoesNotExist(let path):
                return "File does not exist at path: '\(path)'"
            }
        }
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
    
    private enum CodingKeys: String, CodingKey {
        case caseId
        case path
        case url
    }
    
    private enum CaseId: String, Codable {
        case localFilePath
        case remoteUrl
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        
        switch caseId {
        case .localFilePath:
            let path = try container.decode(String.self, forKey: .path)
            self = .localFilePath(path)
        case .remoteUrl:
            let url = try container.decode(URL.self, forKey: .url)
            self = .remoteUrl(url)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .localFilePath(let path):
            try container.encode(CaseId.localFilePath, forKey: .caseId)
            try container.encode(path, forKey: .path)
        case .remoteUrl(let url):
            try container.encode(CaseId.remoteUrl, forKey: .caseId)
            try container.encode(url, forKey: .url)
        }
    }
    
}
