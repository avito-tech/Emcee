import Foundation
import QueueCommunication
import TestHelpers

public class FakeRemoteQueueDetector: RemoteQueueDetector {
    public init() { }
    
    public func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<Int> {
        return Set()
    }
    
    public var shoudThrow = false
    public var masterPort = 0
    public func findMasterQueuePort(timeout: TimeInterval) throws -> Int {
        if shoudThrow {
            throw ErrorForTestingPurposes(text: "FindMasterQueuePort error")
        }
        return masterPort
    }
    
    
}
