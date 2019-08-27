import Foundation
import Models
import RESTMethods

public protocol RequestSignatureVerifyingRESTEndpoint: RESTEndpoint where DecodedObjectType: SignedRequest {
    var expectedRequestSignature: RequestSignature { get }
    func handle(verifiedRequest: DecodedObjectType) throws -> ResponseType
}

public struct RequestSignatureMismatch: Error, CustomStringConvertible {
    public let expectedRequestSignature: RequestSignature
    public let actualRequestSignature: RequestSignature

    public var description: String {
        return "Request has unexpected signature, expected: \(expectedRequestSignature), actual: \(actualRequestSignature)"
    }
}

public extension RequestSignatureVerifyingRESTEndpoint {
    func handle(decodedRequest: DecodedObjectType) throws -> ResponseType {
        guard expectedRequestSignature == decodedRequest.requestSignature else {
            throw RequestSignatureMismatch(
                expectedRequestSignature: expectedRequestSignature,
                actualRequestSignature: decodedRequest.requestSignature
            )
        }
        return try handle(verifiedRequest: decodedRequest)
    }
}

