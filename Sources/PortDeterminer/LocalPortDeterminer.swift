import Darwin
import Foundation
import EmceeLogging
import Socket
import SocketModels

public final class LocalPortDeterminer {
    private let logger: ContextualLogger
    private let portRange: ClosedRange<SocketModels.Port>
    
    public init(
        logger: ContextualLogger,
        portRange: ClosedRange<SocketModels.Port>
    ) {
        self.logger = logger
        self.portRange = portRange
    }
    
    public enum LocalPortDeterminerError: Error, CustomStringConvertible {
        case noAvailablePorts(portRange: ClosedRange<SocketModels.Port>)
        
        public var description: String {
            switch self {
            case .noAvailablePorts(let portRange):
                return "No free TCP ports found in range \(portRange)"
            }
        }
    }
    
    public func availableLocalPort() throws -> SocketModels.Port {
        for port in portRange {
            logger.trace("Checking availability of local port \(port)")
            if isPortAvailable(port: UInt16(port.value)) {
                logger.trace("Port \(port) appears to be available")
                return port
            }
        }
        throw LocalPortDeterminerError.noAvailablePorts(portRange: portRange)
    }
    
    private func isPortAvailable(port: in_port_t) -> Bool {
        do {
            guard let signature = try Socket.Signature(
                protocolFamily: .inet,
                socketType: .stream,
                proto: .tcp,
                hostname: "localhost",
                port: Int32(port)
            ) else {
                logger.warning("Can't create socket signature for port \(port)")
                return false
            }
            
            let socket = try Socket.create(connectedUsing: signature)
            if socket.isConnected {
                socket.close()
                return false
            }
            return true
        } catch {
            // connection failure means port is free
            return true
        }
    }
}
