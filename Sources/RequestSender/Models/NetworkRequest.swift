import Foundation

public protocol NetworkRequest {
    associatedtype Payload: Encodable
    associatedtype Response: Decodable

    var httpMethod: HTTPMethod { get }
    var payload: Payload? { get }
    var pathWithLeadingSlash: String { get }
    var timeout: TimeInterval { get }
}

public extension NetworkRequest {
    var timeout: TimeInterval { 60 } // this matches URLRequest default value
}
