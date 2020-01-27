import Foundation
import RESTServer

public final class FakeRESTEndpoint<PayloadType: Decodable, ReturnType: Encodable>: RESTEndpoint {
    private let returnValue: ReturnType

    public init(_ returnValue: ReturnType) {
        self.returnValue = returnValue
    }
    
    public func handle(decodedPayload: PayloadType) throws -> ReturnType {
        return returnValue
    }
}
