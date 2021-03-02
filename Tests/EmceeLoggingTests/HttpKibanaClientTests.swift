import DateProviderTestHelpers
import EmceeLogging
import SocketModels
import TestHelpers
import URLSessionTestHelpers
import XCTest

final class HttpKibanaClientTests: XCTestCase {
    lazy var client = HttpKibanaClient(
        dateProvider: dateProvider,
        endpoints: [.http(SocketAddress(host: "example.com", port: 42))],
        indexPattern: "index-pattern-thing-",
        urlSession: urlSession
    )
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    lazy var urlSession = FakeURLSession()
    
    func test() throws {
        try client.send(
            level: "level",
            message: "message",
            metadata: [
                "one": "thing"
            ]
        ) { _ in }
        
        let urlTask = urlSession.providedDataTasks[0]
        let request = urlTask.originalTask.originalRequest
        
        XCTAssertEqual(request?.httpMethod, "POST")
        XCTAssertEqual(request?.url?.absoluteString, "http://example.com:42/index-pattern-thing-/_doc")
        
        let bodyPayload = try JSONDecoder().decode([String: String].self, from: assertNotNil { request?.httpBody })
        
        assert {
            bodyPayload
        } equals: {
            [
                "message": "message",
                "level": "level",
                "@timestamp": "1970-01-01T03:01:40.000Z",
                "one": "thing",
            ]
        }
    }
    
    func test___completion_is_called() throws {
        let completionCalled = XCTestExpectation(description: "completion called")
        
        try client.send(
            level: "level",
            message: "message",
            metadata: [:]
        ) { _ in completionCalled.fulfill() }
        
        urlSession.providedDataTasks[0].completionHandler(nil, nil, nil)
        
        wait(for: [completionCalled], timeout: 0)
    }
}

