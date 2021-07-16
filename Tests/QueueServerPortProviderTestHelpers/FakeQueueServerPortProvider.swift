import Foundation
import SocketModels
import QueueServerPortProvider

public final class FakeQueueServerPortProvider: QueueServerPortProvider {
    private let result: SocketModels.Port
    
    public init(port: SocketModels.Port) {
        self.result = port
    }
    
    public func port() throws -> SocketModels.Port {
        result
    }
}
