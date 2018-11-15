import Foundation
import RESTMethods

public protocol RESTEndpoint {
    associatedtype DecodedObjectType: Decodable
    func handle(decodedRequest: DecodedObjectType) throws -> RESTResponse
}
