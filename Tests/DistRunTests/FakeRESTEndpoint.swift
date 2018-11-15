import DistRun
import Foundation
import RESTMethods

class FakeRESTEndpoint<V: Decodable>: RESTEndpoint {
    public typealias T = V
    
    private let returnValue: RESTResponse

    public init(returnValue: RESTResponse = .workerBlocked) {
        self.returnValue = returnValue
    }
    
    public func handle(decodedRequest: T) throws -> RESTResponse {
        return returnValue
    }
}
