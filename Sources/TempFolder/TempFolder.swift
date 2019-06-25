import Basic
import Foundation

public final class TempFolder: Hashable {
    private let temporaryDirectory: TemporaryDirectory
    
    public static func with(stringPath: String) throws -> TempFolder {
        return try TempFolder(path: try AbsolutePath(validating: stringPath))
    }
    
    public init(path: AbsolutePath? = nil, cleanUpAutomatically: Bool = true) throws {
        if let path = path {
            try FileManager.default.createDirectory(atPath: path.asString, withIntermediateDirectories: true)
        }
        temporaryDirectory = try TemporaryDirectory(dir: path, removeTreeOnDeinit: cleanUpAutomatically)
    }
    
    public func pathWith(components: [String]) -> AbsolutePath {
        var path = temporaryDirectory.path
        components.forEach { path = path.appending(component: $0) }
        return path
    }
    
    public func pathByCreatingDirectories(components: [String]) throws -> AbsolutePath {
        let path = pathWith(components: components)
        try FileManager.default.createDirectory(atPath: path.asString, withIntermediateDirectories: true)
        return path
    }
    
    @discardableResult
    public func createFile(components: [String] = [], filename: String, contents: Data? = nil) throws -> AbsolutePath {
        let container = try pathByCreatingDirectories(components: components)
        let path = container.appending(component: filename)
        FileManager.default.createFile(atPath: path.asString, contents: contents, attributes: [:])
        return path
    }
    
    public static func == (left: TempFolder, right: TempFolder) -> Bool {
        return left.temporaryDirectory.path == right.temporaryDirectory.path
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(temporaryDirectory.path)
    }
}
