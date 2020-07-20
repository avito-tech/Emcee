import Foundation
import Models
import QueueModels

public protocol RemotePortDeterminer {
    func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [Models.Port: Version]
}
