import Foundation
import RemotePortDeterminer
import Models

public enum RemoteQueueDetectorError: Error, CustomStringConvertible {
    case noMasterQueueFound
    
    public var description: String {
        switch self {
        case .noMasterQueueFound:
            return "No master queue is found! May be no queues are running at all"
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
    
    public func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<Int> {
        let availableQueues = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: timeout)
        let ports = availableQueues
            .filter { keyValue -> Bool in keyValue.value == emceeVersion }
            .map { $0.key }
        return Set(ports)
    }
    
    public func findMasterQueuePort(timeout: TimeInterval) throws -> Int {
        let availableQueues = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: timeout)
    
        let sortedQueues = availableQueues
            .sorted { (left, right) -> Bool in
                left.value > right.value
            }
        
        guard let masterPort = sortedQueues.first?.key else {
            throw RemoteQueueDetectorError.noMasterQueueFound
        }
        
        return masterPort
    }
}
