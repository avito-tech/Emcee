import Foundation
import Logging
import Models
import QueueClient
import Version

public final class RemoteQueuePortScanner: RemotePortDeterminer {
    private let host: String
    private let portRange: ClosedRange<Int>
    private let workerId: String
    
    public init(host: String, portRange: ClosedRange<Int>, workerId: String) {
        self.host = host
        self.portRange = portRange
        self.workerId = workerId
    }
    
    public func queryPortAndQueueServerVersion() -> [Int: Version] {
        return portRange.reduce([Int: Version]()) { (result, port) -> [Int: Version] in
            var result = result
            let client = SynchronousQueueClient(
                queueServerAddress: SocketAddress(host: host, port: port),
                workerId: workerId
            )
            Logger.debug("Checking availability of \(host):\(port)")
            if let version = try? client.fetchQueueServerVersion() {
                Logger.debug("Found queue server with \(version) version at \(host):\(port)")
                result[port] = version
            }
            return result
        }
    }
}
