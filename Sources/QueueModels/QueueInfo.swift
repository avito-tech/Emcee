import Foundation
import SocketModels

public struct QueueInfo: Codable, Comparable, Hashable {
    public static func < (lhs: QueueInfo, rhs: QueueInfo) -> Bool {
        if lhs.queueAddress == rhs.queueAddress {
            return lhs.queueVersion < rhs.queueVersion
        }
        return lhs.queueAddress.asString < rhs.queueAddress.asString
    }
    
    public let queueAddress: SocketAddress
    public let queueVersion: Version
    
    public init(
        queueAddress: SocketAddress,
        queueVersion: Version
    ) {
        self.queueAddress = queueAddress
        self.queueVersion = queueVersion
    }
}
