import Darwin
import Foundation
import PathLib

public final class TemporaryFolder {
    public let absolutePath: AbsolutePath
    private let deleteOnDealloc: Bool
    
    public init(
        containerPath: AbsolutePath? = nil,
        prefix: String = "TemporaryFolder",
        deleteOnDealloc: Bool = true
    ) throws {
        if let containerPath = containerPath {
            try FileManager.default.createDirectory(atPath: containerPath)
        }
        let containerPath = containerPath ?? AbsolutePath(NSTemporaryDirectory())
        let pathTemplate = containerPath.appending(component: "\(prefix).XXXXXX")
        var templateBytes = [UInt8](pathTemplate.pathString.utf8).map { Int8($0) } + [Int8(0)]
        if mkdtemp(&templateBytes) == nil {
            throw ErrnoError.failedToCreateTemporaryFolder(pathTemplate, code: errno)
        }
        
        let resultingPath = String(cString: templateBytes)
        let urlValues = try URL(fileURLWithPath: resultingPath).resourceValues(forKeys: [.canonicalPathKey])
        guard let canonicalPath = urlValues.canonicalPath else {
            throw UnknownCanonicalPath(path: resultingPath)
        }
        
        self.absolutePath = AbsolutePath(canonicalPath)
        self.deleteOnDealloc = deleteOnDealloc
    }
    
    deinit {
        if deleteOnDealloc {
            try? FileManager.default.removeItem(atPath: absolutePath.pathString)
        } else {
            rmdir(absolutePath.pathString)
        }
    }
    
    public func pathWith(components: [String]) -> AbsolutePath {
        return absolutePath.appending(components: components)
    }
    
    public func pathByCreatingDirectories(components: [String]) throws -> AbsolutePath {
        let path = pathWith(components: components)
        try FileManager.default.createDirectory(atPath: path)
        return path
    }
    
    @discardableResult
    public func createFile(components: [String] = [], filename: String, contents: Data? = nil) throws -> AbsolutePath {
        let container = try pathByCreatingDirectories(components: components)
        let path = container.appending(component: filename)
        FileManager.default.createFile(atPath: path.pathString, contents: contents)
        return path
    }
    
    public static func == (left: TemporaryFolder, right: TemporaryFolder) -> Bool {
        return left.absolutePath == right.absolutePath
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(absolutePath)
    }
}
