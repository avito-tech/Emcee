import Foundation
import Models
import QueueCommunication
import TestHelpers

public class FakeRemoteQueueDetector: RemoteQueueDetector {
    public init() { }
    
    public func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<Models.Port> {
        return Set()
    }
    
    public var shoudThrow = false
    public var masterPort: Models.Port = 0
    public func findMasterQueuePort(timeout: TimeInterval) throws -> Models.Port {
        if shoudThrow {
            throw ErrorForTestingPurposes(text: "FindMasterQueuePort error")
        }
        return masterPort
    }
    
    
}
