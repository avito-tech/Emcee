import Foundation
import RESTMethods
import Swifter
import Logging

public final class QueueServerRequestParser {
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func parse<T>(
        request: HttpRequest,
        responseProducer: (T) throws -> (RESTResponse))
        -> HttpResponse
        where T: Decodable
    {
        let requestData = Data(bytes: request.body)
        do {
            let object: T = try decoder.decode(T.self, from: requestData)
            let restResponse = try responseProducer(object)
            return .json(response: restResponse)
        } catch {
            log("Failed to process \(request.path) data: \(error). Will return server error response.")
            return .internalServerError
        }
    }
}
