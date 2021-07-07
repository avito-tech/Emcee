import Foundation
import QueueCommunication
import SocketModels
import TestHelpers

public class FakeRemoteQueueDetector: RemoteQueueDetector {
    public init() { }
    
    public func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<SocketAddress> {
        return Set()
    }
    
    public var shoudThrow = false
    public var masterAddress = SocketAddress(host: "localhost", port: 0)
    public func findMasterQueueAddress(timeout: TimeInterval) throws -> SocketAddress {
        if shoudThrow {
            throw ErrorForTestingPurposes(text: "FindMasterQueuePort error")
        }
        return masterAddress
    }
}
