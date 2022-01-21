import Foundation
import SocketModels

public final class ClientDetails: Codable, Hashable {
    public let socketAddress: SocketAddress
    public let clientLogStreamingMode: ClientLogStreamingMode
    
    public init(
        socketAddress: SocketAddress,
        clientLogStreamingMode: ClientLogStreamingMode
    ) {
        self.socketAddress = socketAddress
        self.clientLogStreamingMode = clientLogStreamingMode
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(socketAddress)
        hasher.combine(clientLogStreamingMode)
    }
    
    public static func == (lhs: ClientDetails, rhs: ClientDetails) -> Bool {
        return lhs.socketAddress == rhs.socketAddress
        && lhs.clientLogStreamingMode == rhs.clientLogStreamingMode
    }
}
