import Foundation

public protocol FilePropertiesContainer {
    func modificationDate() throws -> Date
}
