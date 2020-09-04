import Foundation
import Logging
import Network
import SocketModels

public final class StatsdClientImpl: StatsdClient {
    struct InvalidPortValue: Error, CustomStringConvertible {
        let value: Int
        var description: String {
            return "Invalid port value \(value)"
        }
    }
    
    private let connection: NWConnection
    
    public init(
        statsdSocketAddress: SocketAddress
    ) throws {
        guard let port = NWEndpoint.Port(rawValue: UInt16(statsdSocketAddress.port.value)) else {
            throw InvalidPortValue(value: statsdSocketAddress.port.value)
        }
        
        self.connection = NWConnection(
            host: .name(statsdSocketAddress.host, nil),
            port: port,
            using: .udp
        )
    }
    
    public var stateUpdateHandler: ((NWConnection.State) -> Void)? {
        get { connection.stateUpdateHandler }
        set { connection.stateUpdateHandler = newValue }
    }
    
    public var state: NWConnection.State {
        connection.state
    }
    
    public func start(queue: DispatchQueue) {
        connection.start(queue: queue)
    }
    
    public func cancel() {
        connection.cancel()
    }
    
    public func send(content: Data) {
        connection.send(
            content: content,
            completion: NWConnection.SendCompletion.contentProcessed {
                if let error = $0 {
                    Logger.error("Statsd metric send failed: \(error)")
                }
            }
        )
    }
}
