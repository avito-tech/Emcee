import FileSystem
import Foundation
import PathLib

public class FakeFilePropertiesContainer: FilePropertiesContainer {
    public let path: AbsolutePath
    public var mdate = Date(timeIntervalSince1970: 500)
    
    public init(path: AbsolutePath) {
        self.path = path
    }
    
    public func modificationDate() throws -> Date {
        return mdate
    }
}
