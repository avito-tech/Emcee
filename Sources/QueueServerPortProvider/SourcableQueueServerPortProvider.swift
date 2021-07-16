import Foundation
import SocketModels

public final class SourcableQueueServerPortProvider: QueueServerPortProvider {
    public weak var source: QueueServerPortProvider?
    
    public init() {}
    
    public struct UnknownPortError: Error, CustomStringConvertible {
        public let description = "Queue server port cannot be determined because source is nil"
    }
    
    public func port() throws -> SocketModels.Port {
        guard let source = source else {
            throw UnknownPortError()
        }
        
        return try source.port()
    }
}
