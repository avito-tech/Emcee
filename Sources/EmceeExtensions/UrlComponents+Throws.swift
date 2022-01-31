import Foundation

public struct CannotBuildUrl: Error, CustomStringConvertible {
    public let components: URLComponents
    
    public var description: String {
        "Cannot build URL from components: \(components)"
    }
}

extension URLComponents {
    public func createUrl() throws -> URL {
        guard let url = self.url else {
            throw CannotBuildUrl(components: self)
        }
        return url
    }
}
