import Foundation
import Models
import QueueServer
import RESTMethods
import XCTest

class RequestSignatureVerifyingRESTEndpointTests: XCTestCase {
    let expectedRequestSignature = RequestSignature(value: "expected")
    let unexpectedRequestSignature = RequestSignature(value: "unexpected")

    func test___expected_request_signature_allows_execution_of_handler() {
        let endpoint = FakeVerifyingEndpoint(
            expectedRequestSignature: expectedRequestSignature,
            response: "good"
        )
        let request = FakeSignedRequest(
            requestSignature: expectedRequestSignature
        )
        XCTAssertEqual(
            try endpoint.handle(decodedRequest: request),
            "good"
        )
    }

    func test___mismatching_request_signature_prevents_execution_of_handler() {
        let endpoint = FakeVerifyingEndpoint(
            expectedRequestSignature: expectedRequestSignature,
            response: "good"
        )
        let request = FakeSignedRequest(
            requestSignature: unexpectedRequestSignature
        )
        XCTAssertThrowsError(
            try endpoint.handle(decodedRequest: request)
        )
    }
}

class FakeSignedRequest: SignedRequest, Codable {
    let requestSignature: RequestSignature

    init(requestSignature: RequestSignature) {
        self.requestSignature = requestSignature
    }
}

class FakeVerifyingEndpoint: RequestSignatureVerifyingRESTEndpoint {
    typealias DecodedObjectType = FakeSignedRequest
    typealias ResponseType = String

    let expectedRequestSignature: RequestSignature
    let response: String

    init(expectedRequestSignature: RequestSignature, response: String) {
        self.expectedRequestSignature = expectedRequestSignature
        self.response = response
    }

    func handle(verifiedRequest: FakeSignedRequest) throws -> String {
        return response
    }
}
