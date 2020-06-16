import Foundation
import Models

public protocol RemotePortDeterminer {
    func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [Models.Port: Version]
}
