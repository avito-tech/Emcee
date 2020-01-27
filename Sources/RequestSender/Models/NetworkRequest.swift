import Models
import Foundation

public protocol NetworkRequest {
    associatedtype Payload: Encodable
    associatedtype Response: Decodable

    var httpMethod: HTTPMethod { get }
    var payload: Payload? { get }
    var pathWithLeadingSlash: String { get }
}
