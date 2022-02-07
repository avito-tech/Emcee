import Foundation
import LogStreamingModels
import QueueModels
import SocketModels

/// Stores associations between who added specific `BucketId` into a queue.
public protocol ClientDetailsHolder {
    func associate(bucketId: BucketId, clientDetails: ClientDetails)
    func clientDetails(bucketId: BucketId) -> ClientDetails?
    func forget(clientDetails: ClientDetails)
    
    var knownClientDetails: Set<ClientDetails> { get }
}
