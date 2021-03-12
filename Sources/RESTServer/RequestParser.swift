import Foundation
import Swifter
import EmceeLogging

public final class RequestParser {
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func parse<T, R>(
        request: HttpRequest,
        responseProducer: (T) throws -> (R))
        -> HttpResponse
        where T: Decodable, R: Encodable
    {
        let requestData = Data(request.body)
        do {
            let object: T = try decoder.decode(T.self, from: requestData)
            return .json(response: try responseProducer(object))
        } catch {
            let errorString = "Failed to process request with path \"\(request.path)\", error: \"\(error)\""
            return .badRequest(HttpResponseBody.text(errorString))
        }
    }
}
