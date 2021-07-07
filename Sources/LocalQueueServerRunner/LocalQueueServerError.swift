import QueueModels
import SocketModels

public enum LocalQueueServerError: Error, CustomStringConvertible {
    case sameVersionQueueIsAlreadyRunning(address: SocketAddress, version: Version)
    
    public var description: String {
        switch self {
        case let .sameVersionQueueIsAlreadyRunning(address, version):
            return "Queue server with version \(version) is already running at \(address)"
        }
    }
}
