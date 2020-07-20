import Foundation
import QueueModels

public protocol SignedPayload {
    var payloadSignature: PayloadSignature { get }
}
