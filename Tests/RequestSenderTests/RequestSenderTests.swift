import Foundation
import Models
import RequestSender
import Swifter
import XCTest
import ModelsTestHelpers
import RequestSenderTestHelpers

final class RequestSenderTests: XCTestCase {
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    
    func test__failing_request() throws {
        let sender = RequestSenderFixtures.localhostRequestSender(
            port: 49151 // officially reserved port https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
        )
        
        let callbackCalled = expectation(description: "callback has been called")
        sender.sendRequestWithCallback(
            pathWithSlash: "/",
            payload: ["foo": "bar"],
            callbackQueue: callbackQueue,
            callback: { (result: Either<String, RequestSenderError>) in
                XCTAssertTrue(result.isError)
                callbackCalled.fulfill()
            }
        )
        wait(for: [callbackCalled], timeout: 10)
    }
    
    func test__success_request() throws {
        let server = HttpServer()
        server["/"] = { _ in HttpResponse.ok(.json(["response": "baz"] as NSDictionary)) }
        try server.start()
        
        let sender = RequestSenderImpl(
            urlSession: URLSession(configuration: .default),
            queueServerAddress: SocketAddress(
                host: "localhost",
                port: try server.port()
            )
        )
        
        let callbackCalled = expectation(description: "callback has been called")
        sender.sendRequestWithCallback(
            pathWithSlash: "/",
            payload: ["foo": "bar"],
            callbackQueue: callbackQueue,
            callback: { (result: Either<[String: String], RequestSenderError>) in
                XCTAssertEqual(
                    try? result.dematerialize(),
                    ["response": "baz"]
                )
                callbackCalled.fulfill()
            }
        )
        wait(for: [callbackCalled], timeout: 10)
    }
}

