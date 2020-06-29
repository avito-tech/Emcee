import Foundation

public protocol FilePropertiesContainer {
    func modificationDate() throws -> Date
    func isExecutable() throws -> Bool
    func exists() throws -> Bool
    func isDirectory() throws -> Bool
    func isRegularFile() throws -> Bool
    func size() throws -> Int
}
