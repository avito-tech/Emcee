import Foundation
import LogStreamingModels
import QueueModels
import SocketModels

public final class NoOpClientDetailsHolder: ClientDetailsHolder {
    public static let instance = NoOpClientDetailsHolder()
    
    private init() {}
    
    public func associate(bucketId: BucketId, clientDetails: ClientDetails) {}
    public func clientDetails(bucketId: BucketId) -> ClientDetails? { nil }
    public func forget(clientDetails: ClientDetails) {}
    
    public let knownClientDetails: Set<ClientDetails> = []
}
