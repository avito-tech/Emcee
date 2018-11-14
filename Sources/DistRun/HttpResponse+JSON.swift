import Foundation
import Logging
import RESTMethods
import Swifter

public extension HttpResponse {
    
    private static let restResponseEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    
    public static func json(response: RESTResponse) -> HttpResponse {
        do {
            let data = try restResponseEncoder.encode(response)
            return .raw(200, "OK", ["Content-Type": "application/json"]) {
                try $0.write(data)
            }
        } catch {
            log("Failed to generate JSON response: \(error). Will return server error response.")
            return .internalServerError
        }
    }
}
