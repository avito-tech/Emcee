import FileSystem
import Foundation
import PathLib

public class FakeFilePropertiesContainer: FilePropertiesContainer {
    public let path: AbsolutePath
    public var mdate = Date(timeIntervalSince1970: 500)
    public var executable = false
    
    public init(path: AbsolutePath) {
        self.path = path
    }
    
    public func modificationDate() throws -> Date { mdate }
    
    public func isExecutable() throws -> Bool { executable }
}
