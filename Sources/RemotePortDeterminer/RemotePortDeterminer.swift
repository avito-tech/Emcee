import Foundation
import QueueModels
import SocketModels

public protocol RemotePortDeterminer {
    func queryPortAndQueueServerVersion(timeout: TimeInterval) -> [SocketModels.Port: Version]
}
