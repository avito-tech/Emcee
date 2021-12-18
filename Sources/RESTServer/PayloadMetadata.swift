import Foundation

public struct PayloadMetadata {
    public let requesterAddress: String
    
    public init(requesterAddress: String) {
        self.requesterAddress = requesterAddress
    }
}
