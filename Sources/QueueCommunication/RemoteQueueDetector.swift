import Foundation

public protocol RemoteQueueDetector {
    func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<Int>
    func findMasterQueuePort(timeout: TimeInterval) throws -> Int
}
