import EmceeLoggingModels
import Foundation
import RESTInterfaces
import RESTServer
import RequestSender

public final class LogEntryEndpoint: RESTEndpoint {
    public let path: RESTPath = LogEntryRestPath()
    public let requestIndicatesActivity: Bool = false
    public let logStreamer: LogStreamer
    
    public init(logStreamer: LogStreamer) {
        self.logStreamer = logStreamer
    }
    
    public func handle(payload: LogEntry) throws -> VoidPayload {
        logStreamer.stream(logEntry: payload)
        return VoidPayload()
    }
}
