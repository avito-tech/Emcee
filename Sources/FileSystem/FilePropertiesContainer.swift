import Foundation

public protocol FilePropertiesContainer {
    func modificationDate() throws -> Date
    func set(modificationDate: Date) throws
    
    func isExecutable() throws -> Bool
    func exists() throws -> Bool
    func isDirectory() throws -> Bool
    func isRegularFile() throws -> Bool
    func size() throws -> Int
}

public extension FilePropertiesContainer {
    func touch() throws { try set(modificationDate: Date()) }
}
