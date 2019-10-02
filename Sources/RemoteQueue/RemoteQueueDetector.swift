import Foundation
import RemotePortDeterminer
import Version

public final class RemoteQueueDetector {
    private let localQueueClientVersionProvider: VersionProvider
    private let remotePortDeterminer: RemotePortDeterminer

    public init(
        localQueueClientVersionProvider: VersionProvider,
        remotePortDeterminer: RemotePortDeterminer)
    {
        self.localQueueClientVersionProvider = localQueueClientVersionProvider
        self.remotePortDeterminer = remotePortDeterminer
    }
    
    public func findSuitableRemoteRunningQueuePorts(timeout: TimeInterval) throws -> Set<Int> {
        let localVersion = try localQueueClientVersionProvider.version()
        let availableQueues = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: timeout)
        let ports = availableQueues
            .filter { keyValue -> Bool in keyValue.value == localVersion }
            .map { $0.key }
        return Set(ports)
    }
}
