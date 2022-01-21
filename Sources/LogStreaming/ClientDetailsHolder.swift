import Foundation
import QueueModels
import SocketModels

/// Stores associations between who added specific `BucketId` into a queue.
public protocol ClientDetailsHolder {
    func associate(bucketId: BucketId, clientRestAddress: SocketAddress)
    func clientRestAddress(bucketId: BucketId) -> SocketAddress?
    func forget(socketAddress: SocketAddress)
    
    var knownClientRestAddresses: Set<SocketAddress> { get }
}
