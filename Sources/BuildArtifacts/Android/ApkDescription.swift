import Foundation

public struct ApkDescription: Codable, Hashable, CustomStringConvertible {
    public let location: ApkLocation
    public let package: String
    
    public init(
        location: ApkLocation,
        package: String
    ) {
        self.location = location
        self.package = package
    }
    
    public var description: String {
        "<\(location) package: \(package)>"
    }
}
