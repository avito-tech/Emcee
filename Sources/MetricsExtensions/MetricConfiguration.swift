import Foundation
import SocketModels

public struct MetricConfiguration: Codable, Hashable {
    public let socketAddress: SocketAddress
    public let metricPrefix: String

    public init(socketAddress: SocketAddress, metricPrefix: String) {
        self.socketAddress = socketAddress
        self.metricPrefix = metricPrefix
    }
}
