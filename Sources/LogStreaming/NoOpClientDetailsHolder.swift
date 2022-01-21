import Foundation
import QueueModels
import SocketModels

public final class NoOpClientDetailsHolder: ClientDetailsHolder {
    public static let instance = NoOpClientDetailsHolder()
    
    private init() {}
    
    public func associate(bucketId: BucketId, clientRestAddress: SocketAddress) {}
    public func clientRestAddress(bucketId: BucketId) -> SocketAddress? { nil }
    public func forget(socketAddress: SocketAddress) {}
    
    public let knownClientRestAddresses = Set<SocketAddress>()
}
