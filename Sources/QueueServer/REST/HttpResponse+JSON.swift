import Foundation
import Logging
import Swifter

public extension HttpResponse {
    private static let responseEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    
    public static func json<R: Encodable>(response: R) -> HttpResponse {
        do {
            let data = try responseEncoder.encode(response)
            return .raw(200, "OK", ["Content-Type": "application/json"]) {
                try $0.write(data)
            }
        } catch {
            Logger.error("Failed to generate JSON response: \(error). Will return server error response.")
            return .internalServerError
        }
    }
}
