import Foundation
import PathLib

public final class DefaultFilePropertiesContainer: FilePropertiesContainer {
    private let path: AbsolutePath
    
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
}
