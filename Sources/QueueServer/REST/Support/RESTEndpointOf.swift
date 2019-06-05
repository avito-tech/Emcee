import Foundation

public final class RESTEndpointOf<RequestType: Decodable, ReturnType: Encodable>: RESTEndpoint {
    public typealias DecodedObjectType = RequestType
    public typealias ResponseType = ReturnType
    
    private let internalHandler: (RequestType) throws -> ReturnType
    
    public init<EndpointType: RESTEndpoint>(
        actualHandler: EndpointType) where
        EndpointType.DecodedObjectType == RequestType,
        EndpointType.ResponseType == ReturnType
    {
        internalHandler = { (request: RequestType) throws -> ReturnType in
            try actualHandler.handle(decodedRequest: request)
        }
    }
    
    public func handle(decodedRequest: RequestType) throws -> ReturnType {
        return try internalHandler(decodedRequest)
    }
}
