import Foundation
import Models
import RESTMethods
import RESTServer
import XCTest

class RequestSignatureVerifyingRESTEndpointTests: XCTestCase {
    let expectedPayloadSignature = PayloadSignature(value: "expected")
    let unexpectedPayloadSignature = PayloadSignature(value: "unexpected")

    func test___expected_request_signature_allows_execution_of_handler() {
        let endpoint = FakeVerifyingEndpoint(
            expectedRequestSignature: expectedPayloadSignature,
            response: "good"
        )
        let payload = FakeSignedPayload(
            requestSignature: expectedPayloadSignature
        )
        XCTAssertEqual(
            try endpoint.handle(decodedPayload: payload),
            "good"
        )
    }

    func test___mismatching_request_signature_prevents_execution_of_handler() {
        let endpoint = FakeVerifyingEndpoint(
            expectedRequestSignature: expectedPayloadSignature,
            response: "good"
        )
        let payload = FakeSignedPayload(
            requestSignature: unexpectedPayloadSignature
        )
        XCTAssertThrowsError(
            try endpoint.handle(decodedPayload: payload)
        )
    }
}

class FakeSignedPayload: SignedPayload, Codable {
    let payloadSignature: PayloadSignature

    init(requestSignature: PayloadSignature) {
        self.payloadSignature = requestSignature
    }
}

class FakeVerifyingEndpoint: PayloadSignatureVerifyingRESTEndpoint {
    typealias DecodedObjectType = FakeSignedPayload
    typealias ResponseType = String

    let expectedPayloadSignature: PayloadSignature
    let response: String

    init(expectedRequestSignature: PayloadSignature, response: String) {
        self.expectedPayloadSignature = expectedRequestSignature
        self.response = response
    }

    func handle(verifiedPayload: FakeSignedPayload) throws -> String {
        return response
    }
}
