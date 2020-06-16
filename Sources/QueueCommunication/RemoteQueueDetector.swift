import Foundation
import Models

public protocol RemoteQueueDetector {
    func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<Models.Port>
    func findMasterQueuePort(timeout: TimeInterval) throws -> Models.Port
}
