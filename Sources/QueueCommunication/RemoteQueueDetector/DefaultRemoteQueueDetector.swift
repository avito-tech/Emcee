import Foundation
import EmceeLogging
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
    private let logger: ContextualLogger
    private let remotePortDeterminer: RemotePortDeterminer

    public init(
        emceeVersion: Version,
        logger: ContextualLogger,
        remotePortDeterminer: RemotePortDeterminer)
    {
        self.emceeVersion = emceeVersion
        self.logger = logger
        self.remotePortDeterminer = remotePortDeterminer
    }
    
    public func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<SocketAddress> {
        let availableQueues = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: timeout)
        let ports = availableQueues
            .filter { keyValue -> Bool in keyValue.value == emceeVersion }
            .map { $0.key }
        return Set(ports)
    }
    
    public func findMasterQueueAddress(timeout: TimeInterval) throws -> SocketAddress {
        let availableQueues = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: timeout)
    
        let sortedQueues = availableQueues
            .sorted { (left, right) -> Bool in
                left.value > right.value
            }
        
        guard let masterQueue = sortedQueues.first else {
            throw RemoteQueueDetectorError.noMasterQueueFound
        }
        
        logger.debug("Found master queue with version \(masterQueue.value) at port \(masterQueue.key)")
        return masterQueue.key
    }
}
