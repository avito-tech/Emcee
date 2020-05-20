import Foundation
import RESTInterfaces

public final class RESTEndpointOf<RequestType: Decodable, ReturnType: Encodable>: RESTEndpoint {
    public typealias PayloadType = RequestType
    public typealias ResponseType = ReturnType
    
    private let internalHandler: (RequestType) throws -> ReturnType
    public let path: RESTPath
    public let requestIndicatesActivity: Bool
    
    public init<EndpointType: RESTEndpoint>(
        _ actualHandler: EndpointType
    ) where EndpointType.PayloadType == RequestType,
        EndpointType.ResponseType == ReturnType
    {
        path = actualHandler.path
        requestIndicatesActivity = actualHandler.requestIndicatesActivity
        
        internalHandler = { (request: RequestType) throws -> ReturnType in
            try actualHandler.handle(payload: request)
        }
    }
    
    public func handle(payload: RequestType) throws -> ReturnType {
        return try internalHandler(payload)
    }
}
