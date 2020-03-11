import Foundation
import RemotePortDeterminer
import Models

public final class RemoteQueueDetector {
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
}
