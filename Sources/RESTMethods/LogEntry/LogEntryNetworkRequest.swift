import Foundation
import EmceeLogging
import EmceeLoggingModels
import RequestSender
import RESTInterfaces

public final class LogEntryNetworkRequest: NetworkRequest {
    public typealias Payload = LogEntry
    public typealias Response = VoidPayload
    
    public let httpMethod: HTTPMethod = .post
    public let pathWithLeadingSlash: String = LogEntryRestPath().pathWithLeadingSlash
    public let payload: LogEntry?
    public let timeout: TimeInterval
        
    public init(
        payload: LogEntry,
        timeout: TimeInterval
    ) {
        self.payload = payload
        self.timeout = timeout
    }
}
