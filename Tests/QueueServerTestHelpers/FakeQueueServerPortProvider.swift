import Foundation
import QueueServer
import SocketModels

public final class FakeQueueServerPortProvider: QueueServerPortProvider {
    private let result: SocketModels.Port
    
    public init(port: SocketModels.Port) {
        self.result = port
    }
    
    public func port() throws -> SocketModels.Port {
        result
    }
}
