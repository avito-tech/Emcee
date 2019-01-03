import Foundation
import Logging

public final class RemotePortDeterminer {
    private let host: String
    private let portRange: ClosedRange<Int>
    private let workerId: String

    public init(host: String, portRange: ClosedRange<Int>, workerId: String) {
        self.host = host
        self.portRange = portRange
        self.workerId = workerId
    }
    
    public func queryPortAndQueueServerVersion() -> [Int: String] {
        return portRange.reduce([Int: String]()) { (result, port) -> [Int: String] in
            var result = result
            let client = SynchronousQueueClient(serverAddress: host, serverPort: port, workerId: workerId)
            Logger.debug("Checking availability of \(host):\(port)")
            if let version = try? client.fetchQueueServerVersion() {
                Logger.debug("Found queue server with \(version) version at \(host):\(port)")
                result[port] = version
            }
            return result
        }
    }
}
