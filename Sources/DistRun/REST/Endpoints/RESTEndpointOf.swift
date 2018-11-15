import Foundation
import RESTMethods

public final class RESTEndpointOf<T: Decodable>: RESTEndpoint {
    public typealias DecodedObjectType = T
    
    private let internalHandler: (T) throws -> RESTResponse
    
    public init<C: RESTEndpoint>(actualHandler: C) where C.DecodedObjectType == T {
        internalHandler = { (request: T) throws -> RESTResponse in
            try actualHandler.handle(decodedRequest: request)
        }
    }
    
    public func handle(decodedRequest: T) throws -> RESTResponse {
        return try internalHandler(decodedRequest)
    }
}
