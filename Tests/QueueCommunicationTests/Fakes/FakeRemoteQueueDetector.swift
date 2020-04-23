import Foundation
import QueueCommunication
import TestHelpers

class FakeRemoteQueueDetector: RemoteQueueDetector {
    func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<Int> {
        return Set()
    }
    
    var shoudThrow = false
    var masterPort = 0
    func findMasterQueuePort(timeout: TimeInterval) throws -> Int {
        if shoudThrow {
            throw ErrorForTestingPurposes(text: "FindMasterQueuePort error")
        }
        return masterPort
    }
    
    
}
