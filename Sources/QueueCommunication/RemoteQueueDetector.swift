import Foundation
import SocketModels

public protocol RemoteQueueDetector {
    func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<SocketAddress>
    func findMasterQueueAddress(timeout: TimeInterval) throws -> SocketAddress
}
