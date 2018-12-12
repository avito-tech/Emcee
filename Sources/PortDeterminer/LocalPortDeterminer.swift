import Darwin
import Foundation
import Logging

public final class LocalPortDeterminer {
    private let portRange: ClosedRange<Int>
    
    public init(portRange: ClosedRange<Int>) {
        self.portRange = portRange
    }
    
    public enum LocalPortDeterminerError: Error, CustomStringConvertible {
        case noAvailablePorts(portRange: ClosedRange<Int>)
        
        public var description: String {
            switch self {
            case .noAvailablePorts(let portRange):
                return "No free TCP ports found in range \(portRange)"
            }
        }
    }
    
    public func availableLocalPort() throws -> Int {
        for port in portRange {
            log("Checking availability of local port \(port)")
            if isPortAvailable(port: UInt16(port)) {
                log("Port \(port) appears to be available")
                return port
            }
        }
        throw LocalPortDeterminerError.noAvailablePorts(portRange: portRange)
    }
    
    private func isPortAvailable(port: in_port_t) -> Bool {
        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
        if socketFileDescriptor == -1 {
            return false
        }
        defer { release(socket: socketFileDescriptor) }
        
        var addr = sockaddr_in()
        let sizeOfSockkAddr = MemoryLayout<sockaddr_in>.size
        addr.sin_len = __uint8_t(sizeOfSockkAddr)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(port) : port
        addr.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
        addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        var bind_addr = sockaddr()
        memcpy(&bind_addr, &addr, Int(sizeOfSockkAddr))
        
        if Darwin.bind(socketFileDescriptor, &bind_addr, socklen_t(sizeOfSockkAddr)) == -1 {
            return false
        }
        if listen(socketFileDescriptor, SOMAXCONN ) == -1 {
            return false
        }
        
        return true
    }
    
    private func release(socket: Int32) {
        Darwin.shutdown(socket, SHUT_RDWR)
        close(socket)
    }
}
