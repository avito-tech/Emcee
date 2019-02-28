import Foundation

public final class GraphiteConfiguration: Codable, Equatable {
    public let socketAddress: SocketAddress
    public let metricPrefix: String

    public init(socketAddress: SocketAddress, metricPrefix: String) {
        self.socketAddress = socketAddress
        self.metricPrefix = metricPrefix
    }

    public static func ==(left: GraphiteConfiguration, right: GraphiteConfiguration) -> Bool {
        return left.socketAddress == right.socketAddress
            && left.metricPrefix == right.metricPrefix
    }
}
