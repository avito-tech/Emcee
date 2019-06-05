import Foundation
import Models

public protocol SignedRequest {
    var requestSignature: RequestSignature { get }
}

