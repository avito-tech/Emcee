import Foundation

public enum RequestSenderError: Error, CustomStringConvertible {
    case noData
    case unexpectedResponse(Data)
    case communicationError(Error)
    case parseError(Error, Data)
    case sessionIsClosed(URL)
    case unableToCreateUrl(URLComponents)
    case cannotIssueRequest(Error)
    
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
        case .unableToCreateUrl(let components):
            return "Unable to convert components to url: \(components)"
        case .cannotIssueRequest(let error):
            return "Failed to issue request: \(error)"
        }
    }
}
