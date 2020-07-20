import Foundation
import RemotePortDeterminer
import Models
import QueueModels

public final class RemotePortDeterminerFixture: RemotePortDeterminer {
    private var result = [Models.Port: Version]()

    public init(result: [Models.Port: Version] = [:]) {
        self.result = result
    }
    
    @discardableResult
    public func set(port: Models.Port, version: Version) -> RemotePortDeterminerFixture {
        result.updateValue(version, forKey: port)
        return self
    }
    
    public func build() -> RemotePortDeterminer {
        return self
    }
    
    public func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [Models.Port: Version] {
        return result
    }
}
