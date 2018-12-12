import Foundation
import QueueServer

class FakeRESTEndpoint<RequestType: Decodable, ReturnType: Encodable>: RESTEndpoint {
    private let returnValue: ReturnType

    public init(_ returnValue: ReturnType) {
        self.returnValue = returnValue
    }
    
    public func handle(decodedRequest: RequestType) throws -> ReturnType {
        return returnValue
    }
}
