import Foundation

public protocol RESTEndpoint {
    associatedtype DecodedObjectType: Decodable
    associatedtype ResponseType: Encodable
    
    func handle(decodedPayload: DecodedObjectType) throws -> ResponseType
}
