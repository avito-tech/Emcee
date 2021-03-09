import DateProviderTestHelpers
import EmceeLogging
import SocketModels
import TestHelpers
import URLSessionTestHelpers
import XCTest

final class HttpKibanaClientTests: XCTestCase {
    lazy var client = assertDoesNotThrow {
        try HttpKibanaClient(
            dateProvider: dateProvider,
            endpoints: [.http(SocketAddress(host: "example.com", port: 42))],
            indexPattern: "index-pattern-thing",
            urlSession: urlSession
        )
    }
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    lazy var urlSession = FakeURLSession()
    
    func test() throws {
        let dateComponents = DateComponents(
            calendar: Calendar(identifier: .gregorian),
            timeZone: TimeZone(secondsFromGMT: 3600),
            year: 1975,
            month: 11,
            day: 20,
            hour: 10,
            minute: 0,
            second: 42
        )
        dateProvider.result = assertNotNil { dateComponents.date }
        
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
        XCTAssertEqual(request?.url?.absoluteString, "http://example.com:42/index-pattern-thing/_doc")
        
        let bodyPayload = try JSONDecoder().decode([String: String].self, from: assertNotNil { request?.httpBody })
        
        assert {
            bodyPayload
        } equals: {
            [
                "message": "message",
                "level": "level",
                "@timestamp": "1975-11-20T09:00:42.000Z",
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

