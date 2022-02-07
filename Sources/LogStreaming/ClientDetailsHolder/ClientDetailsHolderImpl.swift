import CLTExtensions
import Foundation
import LogStreamingModels
import SocketModels
import QueueModels

public final class ClientDetailsHolderImpl: ClientDetailsHolder {
    private var unsafeKnownClientDetails = Set<ClientDetails>()
    private var unsafeClientDetailsByBucketId = [BucketId: ClientDetails]()
    private let lock = NSLock()
    
    public init() {}
    
    public func associate(bucketId: BucketId, clientDetails: ClientDetails) {
        lock.whileLocked {
            unsafeClientDetailsByBucketId[bucketId] = clientDetails
            unsafeKnownClientDetails.insert(clientDetails)
        }
    }
    
    public func clientDetails(bucketId: BucketId) -> ClientDetails? {
        lock.whileLocked {
            unsafeClientDetailsByBucketId[bucketId]
        }
    }
    
    public func forget(clientDetails: ClientDetails) {
        lock.whileLocked {
            unsafeClientDetailsByBucketId = unsafeClientDetailsByBucketId.filter { item in
                item.value != clientDetails
            }
            
            unsafeKnownClientDetails.remove(clientDetails)
        }
    }
    
    public var knownClientDetails: Set<ClientDetails> {
        lock.whileLocked {
            unsafeKnownClientDetails
        }
    }
}
