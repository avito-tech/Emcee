import Foundation
import QueueModels
import RemotePortDeterminer
import SocketModels

public final class RemotePortDeterminerFixture: RemotePortDeterminer {
    private var result = [SocketAddress: Version]()

    public init(result: [SocketAddress: Version] = [:]) {
        self.result = result
    }
    
    @discardableResult
    public func set(socketAddress: SocketAddress, version: Version) -> RemotePortDeterminerFixture {
        result.updateValue(version, forKey: socketAddress)
        return self
    }

    @discardableResult
    public func set(port: SocketModels.Port, version: Version) -> RemotePortDeterminerFixture {
        result.updateValue(version, forKey: SocketAddress(host: "host", port: port))
        return self
    }
    
    public func build() -> RemotePortDeterminer {
        return self
    }
    
    public func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [SocketAddress: Version] {
        return result
    }
}
