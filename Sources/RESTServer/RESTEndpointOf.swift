import Foundation
import RESTInterfaces

public final class RESTEndpointOf<PayloadType: Decodable, ResponseType: Encodable>: RESTEndpoint {
    private let internalHandler: (PayloadType, PayloadMetadata?) throws -> ResponseType
    public let path: RESTPath
    public let requestIndicatesActivity: Bool
    
    public init<EndpointType: RESTEndpoint>(
        _ actualHandler: EndpointType
    ) where EndpointType.PayloadType == PayloadType,
        EndpointType.ResponseType == ResponseType
    {
        path = actualHandler.path
        requestIndicatesActivity = actualHandler.requestIndicatesActivity
        
        internalHandler = { (payload: PayloadType, optionalMetadata: PayloadMetadata?) throws -> ResponseType in
            if let metadata = optionalMetadata {
                return try actualHandler.handle(payload: payload, metadata: metadata)
            } else {
                return try actualHandler.handle(payload: payload)
            }
        }
    }
    
    public func handle(payload: PayloadType) throws -> ResponseType {
        return try internalHandler(payload, nil)
    }
    
    public func handle(payload: PayloadType, metadata: PayloadMetadata) throws -> ResponseType {
        return try internalHandler(payload, metadata)
    }
}
