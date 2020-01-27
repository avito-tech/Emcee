import Foundation
import Models
import RESTMethods

public protocol PayloadSignatureVerifyingRESTEndpoint: RESTEndpoint where DecodedObjectType: SignedPayload {
    var expectedPayloadSignature: PayloadSignature { get }
    func handle(verifiedPayload: DecodedObjectType) throws -> ResponseType
}

public struct PayloadSignatureMismatch: Error, CustomStringConvertible {
    public let expectedPayloadSignature: PayloadSignature
    public let actualPayloadSignature: PayloadSignature

    public var description: String {
        return "Payload has unexpected signature, expected: \(expectedPayloadSignature), actual: \(actualPayloadSignature)"
    }
}

public extension PayloadSignatureVerifyingRESTEndpoint {
    func handle(decodedPayload: DecodedObjectType) throws -> ResponseType {
        guard expectedPayloadSignature == decodedPayload.payloadSignature else {
            throw PayloadSignatureMismatch(
                expectedPayloadSignature: expectedPayloadSignature,
                actualPayloadSignature: decodedPayload.payloadSignature
            )
        }
        return try handle(verifiedPayload: decodedPayload)
    }
}

