import Basic
import Foundation

public final class TempFolder: Hashable {
    private let tempFolder: TemporaryDirectory
    
    public static func with(stringPath: String) throws -> TempFolder {
        return try TempFolder(path: try AbsolutePath(validating: stringPath))
    }
    
    public init(path: AbsolutePath? = nil, cleanUpAutomatically: Bool = true) throws {
        tempFolder = try TemporaryDirectory(dir: path, removeTreeOnDeinit: cleanUpAutomatically)
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: tempFolder.path.asString), withIntermediateDirectories: true)
    }
    
    public var path: AbsolutePath {
        return tempFolder.path
    }
    
    public func pathByCreatingDirectories(components: [String]) throws -> AbsolutePath {
        var path = tempFolder.path
        components.forEach { path = path.appending(component: $0) }
        try FileManager.default.createDirectory(at: URL(fileURLWithPath: path.asString), withIntermediateDirectories: true)
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
        return left.path == right.path
    }
    
    public var hashValue: Int {
        return tempFolder.path.hashValue
    }
}
