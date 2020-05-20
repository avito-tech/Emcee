import Foundation
import Models
import RESTMethods
import RESTInterfaces

public protocol PayloadSignatureVerifyingRESTEndpoint: RESTEndpoint where PayloadType: SignedPayload {
    var expectedPayloadSignature: PayloadSignature { get }
    func handle(verifiedPayload: PayloadType) throws -> ResponseType
}

public struct PayloadSignatureMismatch: Error, CustomStringConvertible {
    public let expectedPayloadSignature: PayloadSignature
    public let actualPayloadSignature: PayloadSignature

    public var description: String {
        return "Payload has unexpected signature, expected: \(expectedPayloadSignature), actual: \(actualPayloadSignature)"
    }
}

public extension PayloadSignatureVerifyingRESTEndpoint {
    func handle(payload: PayloadType) throws -> ResponseType {
        guard expectedPayloadSignature == payload.payloadSignature else {
            throw PayloadSignatureMismatch(
                expectedPayloadSignature: expectedPayloadSignature,
                actualPayloadSignature: payload.payloadSignature
            )
        }
        return try handle(verifiedPayload: payload)
    }
}

