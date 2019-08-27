import Foundation

public protocol RESTEndpoint {
    associatedtype DecodedObjectType: Decodable
    associatedtype ResponseType: Encodable
    
    func handle(decodedRequest: DecodedObjectType) throws -> ResponseType
}
