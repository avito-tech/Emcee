import Foundation
import RemotePortDeterminer
import Models

public final class RemotePortDeterminerFixture: RemotePortDeterminer {
    private var result = [Int: Version]()

    public init(result: [Int: Version] = [:]) {
        self.result = result
    }
    
    @discardableResult
    public func set(port: Int, version: Version) -> RemotePortDeterminerFixture {
        result.updateValue(version, forKey: port)
        return self
    }
    
    public func build() -> RemotePortDeterminer {
        return self
    }
    
    public func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [Int: Version] {
        return result
    }
}
