import Foundation

public enum RequestSenderError: Error, CustomStringConvertible {
    case noData
    case unexpectedResponse(Data)
    case communicationError(Error)
    case parseError(Error, Data)
    case sessionIsClosed(URL)
    case cannotIssueRequest(Error)
    case credentialsNotUTF8
    case badStatusCode(Int, body: Data?)
    
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
        case .sessionIsClosed(let url):
            return "Cannot send request to '\(url)' because session is closed"
        case .cannotIssueRequest(let error):
            return "Failed to issue request: \(error)"
        case .credentialsNotUTF8:
            return "Use UTF8 ecnoding for request credentials"
        case .badStatusCode(let code, let body):
            if let body = body, let bodyString = String(data: body, encoding: .utf8) {
                return "Bad status code \(code), body: \(bodyString)"
            }
            return "Bad status code: \(code)"
        }
    }
}
