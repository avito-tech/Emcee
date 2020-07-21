import Foundation
import QueueCommunication
import SocketModels
import TestHelpers

public class FakeRemoteQueueDetector: RemoteQueueDetector {
    public init() { }
    
    public func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<SocketModels.Port> {
        return Set()
    }
    
    public var shoudThrow = false
    public var masterPort: SocketModels.Port = 0
    public func findMasterQueuePort(timeout: TimeInterval) throws -> SocketModels.Port {
        if shoudThrow {
            throw ErrorForTestingPurposes(text: "FindMasterQueuePort error")
        }
        return masterPort
    }
    
    
}
