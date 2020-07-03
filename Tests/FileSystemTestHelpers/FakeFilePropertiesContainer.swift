import FileSystem
import Foundation
import PathLib

public class FakeFilePropertiesContainer: FilePropertiesContainer {
    public let path: AbsolutePath
    
    public init(path: AbsolutePath) {
        self.path = path
    }
    
    public var mdate = Date(timeIntervalSince1970: 500)
    public func modificationDate() throws -> Date { mdate }
    public func set(modificationDate: Date) throws { mdate = modificationDate }
    
    public var executable = false
    public func isExecutable() throws -> Bool { executable }
    
    public var pathExists = true
    public func exists() throws -> Bool { pathExists }
    
    public var directory = false
    public func isDirectory() throws -> Bool { directory }
    
    public var regularFile = true
    public func isRegularFile() throws -> Bool { regularFile }
    
    public var fileSize = 0
    public func size() throws -> Int { fileSize }
}
