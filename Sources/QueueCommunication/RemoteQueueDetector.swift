import Foundation
import SocketModels

public protocol RemoteQueueDetector {
    func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<SocketModels.Port>
    func findMasterQueuePort(timeout: TimeInterval) throws -> SocketModels.Port
}
