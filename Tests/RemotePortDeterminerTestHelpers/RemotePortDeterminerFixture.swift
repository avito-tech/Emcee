import Foundation
import QueueModels
import RemotePortDeterminer
import SocketModels

public final class RemotePortDeterminerFixture: RemotePortDeterminer {
    private var result = [SocketModels.Port: Version]()

    public init(result: [SocketModels.Port: Version] = [:]) {
        self.result = result
    }
    
    @discardableResult
    public func set(port: SocketModels.Port, version: Version) -> RemotePortDeterminerFixture {
        result.updateValue(version, forKey: port)
        return self
    }
    
    public func build() -> RemotePortDeterminer {
        return self
    }
    
    public func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [SocketModels.Port: Version] {
        return result
    }
}
