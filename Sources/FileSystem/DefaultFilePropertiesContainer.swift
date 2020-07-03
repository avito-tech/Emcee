import Foundation
import PathLib

public final class DefaultFilePropertiesContainer: FilePropertiesContainer {
    private let path: AbsolutePath
    private let fileManager = FileManager()
    
    public init(path: AbsolutePath) {
        self.path = path
    }
    
    public enum DefaultFilePropertiesContainerError: Error, CustomStringConvertible {
        case emptyValue(AbsolutePath, URLResourceKey)
        
        public var description: String {
            switch self {
            case .emptyValue(let path, let property):
                return "File at path \(path) does not have a value for property \(property)"
            }
        }
    }
    
    public func modificationDate() throws -> Date {
        let values = try path.fileUrl.resourceValues(forKeys: [.contentModificationDateKey])
        guard let value = values.contentModificationDate else {
            throw DefaultFilePropertiesContainerError.emptyValue(path, .contentModificationDateKey)
        }
        return value
    }
    
    public func set(modificationDate: Date) throws {
        var values = URLResourceValues()
        values.contentModificationDate = modificationDate
        var url = path.fileUrl
        try url.setResourceValues(values)
    }
    
    public func isExecutable() throws -> Bool {
        let values = try path.fileUrl.resourceValues(forKeys: [.isExecutableKey])
        guard let value = values.isExecutable else {
            throw DefaultFilePropertiesContainerError.emptyValue(path, .isExecutableKey)
        }
        return value
    }
    
    public func exists() throws -> Bool {
        fileManager.fileExists(atPath: path.pathString)
    }
    
    public func isDirectory() throws -> Bool {
        let values = try path.fileUrl.resourceValues(forKeys: [.isDirectoryKey])
        guard let value = values.isDirectory else {
            throw DefaultFilePropertiesContainerError.emptyValue(path, .isDirectoryKey)
        }
        return value
    }
    
    public func isRegularFile() throws -> Bool {
        let values = try path.fileUrl.resourceValues(forKeys: [.isRegularFileKey])
        guard let value = values.isRegularFile else {
            throw DefaultFilePropertiesContainerError.emptyValue(path, .isRegularFileKey)
        }
        return value
    }
    
    public func size() throws -> Int {
        let values = try path.fileUrl.resourceValues(forKeys: [.fileSizeKey])
        guard let value = values.fileSize else {
            throw DefaultFilePropertiesContainerError.emptyValue(path, .fileSizeKey)
        }
        return value
    }
}
