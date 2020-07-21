import Foundation
import Logging
import QueueModels
import RemotePortDeterminer
import SocketModels

public enum RemoteQueueDetectorError: Error, CustomStringConvertible {
    case noMasterQueueFound
    
    public var description: String {
        switch self {
        case .noMasterQueueFound:
            return "No master queue is found! Maybe no queues are running at all"
        }
    }
}

public final class DefaultRemoteQueueDetector: RemoteQueueDetector {
    private let emceeVersion: Version
    private let remotePortDeterminer: RemotePortDeterminer

    public init(
        emceeVersion: Version,
        remotePortDeterminer: RemotePortDeterminer)
    {
        self.emceeVersion = emceeVersion
        self.remotePortDeterminer = remotePortDeterminer
    }
    
    public func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<SocketModels.Port> {
        let availableQueues = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: timeout)
        let ports = availableQueues
            .filter { keyValue -> Bool in keyValue.value == emceeVersion }
            .map { $0.key }
        return Set(ports)
    }
    
    public func findMasterQueuePort(timeout: TimeInterval) throws -> SocketModels.Port {
        let availableQueues = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: timeout)
    
        let sortedQueues = availableQueues
            .sorted { (left, right) -> Bool in
                left.value > right.value
            }
        
        guard let masterQueue = sortedQueues.first else {
            throw RemoteQueueDetectorError.noMasterQueueFound
        }
        
        Logger.debug("Found master queue with version \(masterQueue.value) at port \(masterQueue.key)")
        return masterQueue.key
    }
}
