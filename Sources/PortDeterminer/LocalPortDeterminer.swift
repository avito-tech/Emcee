import Darwin
import Foundation
import EmceeLogging
import SocketModels
import Swifter

public final class LocalPortDeterminer {
    private let portRange: ClosedRange<SocketModels.Port>
    
    public init(portRange: ClosedRange<SocketModels.Port>) {
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
            Logger.debug("Checking availability of local port \(port)")
            if isPortAvailable(port: UInt16(port.value)) {
                Logger.debug("Port \(port) appears to be available")
                return port
            }
        }
        throw LocalPortDeterminerError.noAvailablePorts(portRange: portRange)
    }
    
    private func isPortAvailable(port: in_port_t) -> Bool {
        if let socket = try? Socket.tcpSocketForListen(port) {
            socket.close()
            return true
        } else {
            return false
        }
    }
}
