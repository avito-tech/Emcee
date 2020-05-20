import Foundation
import Models

public protocol SignedPayload {
    var payloadSignature: PayloadSignature { get }
}
