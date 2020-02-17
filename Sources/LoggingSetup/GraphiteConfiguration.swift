import Foundation
import Models

public struct GraphiteConfiguration: Codable, Equatable {
    public let socketAddress: SocketAddress
    public let metricPrefix: String

    public init(socketAddress: SocketAddress, metricPrefix: String) {
        self.socketAddress = socketAddress
        self.metricPrefix = metricPrefix
    }
}
