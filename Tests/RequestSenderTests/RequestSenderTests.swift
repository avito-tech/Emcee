import Extensions
import Foundation
import Models
import ModelsTestHelpers
import RequestSender
import RequestSenderTestHelpers
import Swifter
import Types
import XCTest

final class RequestSenderTests: XCTestCase {
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    private var server = HttpServer()

    override func tearDown() {
        server.stop()
    }
    
    func test__failing_request() throws {
        let sender = RequestSenderFixtures.localhostRequestSender(
            port: 49151 // officially reserved port https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
        )
        
        let callbackCalled = expectation(description: "callback has been called")
        sender.sendRequestWithCallback(
            request: FakeNetworkRequest(),
            callbackQueue: callbackQueue,
            callback: { (result: Either<[String: String], RequestSenderError>) in
                XCTAssertTrue(result.isError)
                callbackCalled.fulfill()
            }
        )
        wait(for: [callbackCalled], timeout: 10)
    }
    
    func test__success_request() throws {
        server["/"] = { _ in HttpResponse.ok(.json(["response": "baz"] as NSDictionary)) }
        startServer()
        
        let sender = RequestSenderFixtures.localhostRequestSender(port: Port(value: try server.port()))
        
        let callbackCalled = expectation(description: "callback has been called")
        sender.sendRequestWithCallback(
            request: FakeNetworkRequest(),
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

    func test__request_with_http_method() throws {
        let httpMethod = HTTPMethod.put
        let requestSent = expectation(description: "Request has been sent")

        server["/"] = { request in
            XCTAssertEqual(request.method, "PUT")
            requestSent.fulfill()

            return HttpResponse.ok(.text("ok"))
        }
        startServer()

        let sender = RequestSenderFixtures.localhostRequestSender(port: Port(value: try server.port()))

        sender.sendRequestWithCallback(
            request: FakeNetworkRequest(httpMethod: httpMethod),
            callbackQueue: callbackQueue,
            callback: { _ in }
        )
        wait(for: [requestSent], timeout: 10)
    }

    func test__request_with_credentials() throws {
        let requestSent = expectation(description: "Request has been sent")
        let credentials = Credentials(username: "username", password: "password")
        let base64Credentials = try "\(credentials.username):\(credentials.password)".base64()
        let expectedAuthHeader = "Basic \(base64Credentials)"

        server["/"] = { request in
            XCTAssertEqual(request.headers["authorization"], expectedAuthHeader)
            requestSent.fulfill()

            return HttpResponse.ok(.text("ok"))
        }
        startServer()

        let sender = RequestSenderFixtures.localhostRequestSender(port: Port(value: try server.port()))

        sender.sendRequestWithCallback(
            request: FakeNetworkRequest(),
            credentials: credentials,
            callbackQueue: callbackQueue,
            callback: { _ in }
        )
        wait(for: [requestSent], timeout: 10)
    }

    func test__request_without_credentials() throws {
        let requestSent = expectation(description: "Request has been sent")

        server["/"] = { request in
            XCTAssertNil(request.headers["authorization"])
            requestSent.fulfill()

            return HttpResponse.ok(.text("ok"))
        }
        startServer()

        let sender = RequestSenderFixtures.localhostRequestSender(port: Port(value: try server.port()))

        sender.sendRequestWithCallback(
            request: FakeNetworkRequest(),
            credentials: nil,
            callbackQueue: callbackQueue,
            callback: { _ in }
        )
        wait(for: [requestSent], timeout: 10)
    }

    func test__request_with_payload() throws {
        let requestSent = expectation(description: "Request has been sent")
        let payload = ["foo": "bar"]

        server["/"] = { request in
            let data = Data(request.body)
            if let decodedBody = try? JSONDecoder().decode(Dictionary<String, String>.self, from: data) {
                XCTAssertEqual(decodedBody, payload)
            } else {
                XCTFail("Could not convert body to json")
            }

            requestSent.fulfill()
            return HttpResponse.ok(.text("ok"))
        }
        startServer()

        let sender = RequestSenderFixtures.localhostRequestSender(port: Port(value: try server.port()))

        sender.sendRequestWithCallback(
            request: FakeNetworkRequest(),
            callbackQueue: callbackQueue,
            callback: { _ in }
        )
        wait(for: [requestSent], timeout: 10)
    }

    func test__request_without_payload() throws {
        let requestSent = expectation(description: "Request has been sent")

        server["/"] = { request in
            XCTAssertEqual(request.body.count, 0)
            requestSent.fulfill()

            return HttpResponse.ok(.text("ok"))
        }
        startServer()

        let sender = RequestSenderFixtures.localhostRequestSender(port: Port(value: try server.port()))

        sender.sendRequestWithCallback(
            request: FakeNetworkRequest(payload: nil),
            callbackQueue: callbackQueue,
            callback: { _ in }
        )
        wait(for: [requestSent], timeout: 10)
    }

    func test__request_404_status_code() throws {
        server["/"] = { request in
            return HttpResponse.notFound
        }
        startServer()

        let sender = RequestSenderFixtures.localhostRequestSender(port: Port(value: try server.port()))

        let callbackCalled = expectation(description: "callback has been called")
        sender.sendRequestWithCallback(
            request: FakeNetworkRequest(),
            callbackQueue: callbackQueue,
            callback: { (result: Either<[String: String], RequestSenderError>) in
                XCTAssertTrue(result.isError)
                do {
                    _ = try result.dematerialize()
                } catch let error {
                    guard let senderError = error as? RequestSenderError else {
                        XCTFail("Wrong error type of \(error)")
                        return
                    }

                    switch senderError {
                    case .badStatusCode(let code):
                        XCTAssertEqual(code, 404)
                    default:
                        XCTFail("Wrong error type of \(error)")
                    }
                }

                callbackCalled.fulfill()
            }
        )
        wait(for: [callbackCalled], timeout: 10)
    }

    /// https://github.com/httpswift/swifter/issues/306
    /// Start the HTTP server in the specified port number, in case of the port number
    /// is being used it would try to find another free port.
    private func startServer(port: in_port_t = 8080, maximumOfAttempts: Int = 10) {

       // Stop the retrying when the attempts is zero
       if maximumOfAttempts == 0 {
          return
       }

       do {
          try server.start(port)
          print("Server has started ( port = \(try server.port()) ). Try to connect now...")
       } catch SocketError.bindFailed(let message) where message == "Address already in use" {
            startServer(port: in_port_t.random(in: 8081..<10000), maximumOfAttempts: maximumOfAttempts - 1)
       } catch {
           print("Server start error: \(error)")
       }
    }
}
