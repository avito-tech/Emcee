import AtomicModels
import Foundation
import SocketModels
import QueueModels

public final class ClientDetailsHolderImpl: ClientDetailsHolder {
    private let storage = AtomicValue<[BucketId: SocketAddress]>([:])
    
    public init() {}
    
    public func associate(bucketId: BucketId, clientRestAddress: SocketAddress) {
        storage.withExclusiveAccess {
            $0[bucketId] = clientRestAddress
        }
    }
    
    public func clientRestAddress(bucketId: BucketId) -> SocketAddress? {
        storage.withExclusiveAccess {
            $0[bucketId]
        }
    }
    
    public func forget(socketAddress: SocketAddress) {
        storage.withExclusiveAccess {
            $0 = $0.filter { element in
                element.value != socketAddress
            }
        }
    }
    
    public var knownClientRestAddresses: Set<SocketAddress> {
        Set(storage.currentValue().values)
    }
}
