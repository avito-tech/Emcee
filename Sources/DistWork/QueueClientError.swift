import Foundation
import RESTMethods

public enum QueueClientError: Error, CustomStringConvertible {
    case noData
    case unexpectedResponse(Data)
    case communicationError(Error)
    case parseError(Error, Data)
    case queueClientIsClosed(RESTMethod)
    
    public var description: String {
        switch self {
        case .noData:
            return "Unexpected response: No data received"
        case .unexpectedResponse(let data):
            let string = String(data: data, encoding: .utf8) ?? "\(data.count) bytes"
            return "Unexpected response: \(string)"
        case .communicationError(let underlyingError):
            return "Response had an error: \(underlyingError)"
        case .parseError(let error, let data):
            let string = String(data: data, encoding: .utf8) ?? "\(data.count) bytes"
            return "Failed to parse response: \(error). Data: \(string)"
        case .queueClientIsClosed(let restMethod):
            return "Queue client has been closed, can't make request to: '\(restMethod)'"
        }
    }
}
