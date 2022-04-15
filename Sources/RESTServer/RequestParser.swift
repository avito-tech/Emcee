import Foundation
import EmceeLogging
import Vapor

public final class RequestParser {
    private let decoder: JSONDecoder
    
    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }
    
    public func parse<T, R>(
        request: Request,
        responseProducer: (T) throws -> (R)
    ) throws -> R where T: Decodable {
        let requestData = Data(buffer: request.body.data!)
        do {
            let object: T = try decoder.decode(T.self, from: requestData)
            return try responseProducer(object)
        } catch {
            let errorString = "Failed to process request with path \"\(request.url)\", error: \"\(error)\""
            throw Abort(.badRequest, reason: errorString)
        }
    }
}
