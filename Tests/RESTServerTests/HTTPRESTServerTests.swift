import AutomaticTerminationTestHelpers
import Foundation
import Models
import RESTInterfaces
import RESTServer
import TestHelpers
import Types
import XCTest

final class HTTPRESTServerTests: XCTestCase {
    lazy var automaticTerminationController = AutomaticTerminationControllerFixture(isTerminationAllowed: false)
    lazy var anyPortProvider = PortProviderWrapper { 0 }
    lazy var server = HTTPRESTServer(
        automaticTerminationController: automaticTerminationController,
        portProvider: anyPortProvider
    )
    
    func test___processing_request() throws {
        server.add(
            handler: RESTEndpointOf(
                FakeEndpoint(
                    requestIndicatesActivity: true,
                    response: .success(["output": "value"])
                )
            )
        )
        
        let port = try server.start()
        let startedTask = startDataTask(port: port, body: ["input": "value"]) { (data, _) in
            guard let data = data, let decodedResponse = try? JSONDecoder().decode([String: String].self, from: data) else {
                self.failTest("Unexpected response")
            }
            XCTAssertEqual(
                decodedResponse,
                ["output": "value"]
            )
        }
        wait(for: [startedTask.waiter], timeout: 10)
    }
    
    func test___processing_throwing_request() throws {
        server.add(
            handler: RESTEndpointOf(
                FakeEndpoint(
                    requestIndicatesActivity: true,
                    response: .error(ErrorForTestingPurposes(text: "error"))
                )
            )
        )
        
        let port = try server.start()
        let startedTask = startDataTask(port: port, body: ["input": "value"]) { (_, response) in
            guard let response = response, let httpResponse = response as? HTTPURLResponse else {
                self.failTest("Unexpected response")
            }
            XCTAssertEqual(httpResponse.statusCode, 400)
        }
        wait(for: [startedTask.waiter], timeout: 10)
    }
    
    func test___processing_request_with_activity___reports_activity() throws {
        server.add(
            handler: RESTEndpointOf(
                FakeEndpoint(
                    requestIndicatesActivity: true,
                    response: .success(["output": "value"])
                )
            )
        )
        
        let port = try server.start()
        let startedTask = startDataTask(port: port, body: ["input": "value"]) { _, _ in }
        wait(for: [startedTask.waiter], timeout: 10)
        
        XCTAssertTrue(automaticTerminationController.indicatedActivityFinished)
    }
    
    func test___processing_request_without_activity___does_not_report_activity() throws {
        server.add(
            handler: RESTEndpointOf(
                FakeEndpoint(
                    requestIndicatesActivity: false,
                    response: .success(["output": "value"])
                )
            )
        )
        
        let port = try server.start()
        let startedTask = startDataTask(port: port, body: ["input": "value"]) { _, _ in }
        wait(for: [startedTask.waiter], timeout: 10)
        
        XCTAssertFalse(automaticTerminationController.indicatedActivityFinished)
    }
    
    func startDataTask<T: Encodable>(
        port: Models.Port,
        body: T,
        completion: @escaping (Data?, URLResponse?) -> ()
    ) -> (task: URLSessionDataTask, waiter: XCTestExpectation) {
        let expectation = XCTestExpectation(description: "data task finished")
        var request = URLRequest(url: URL(string: "http://localhost:\(port)/fake")!)
        request.httpMethod = "POST"
        request.httpBody = assertDoesNotThrow { try JSONEncoder().encode(body) }
        let dataTask = URLSession.shared.dataTask(with: request) { (data, response, _) in
            DispatchQueue.main.sync {
                completion(data, response)
                expectation.fulfill()
            }
        }
        dataTask.resume()
        return (task: dataTask, waiter: expectation)
    }
}

class FakeEndpoint: RESTEndpoint {
    var path: RESTPath = FakeRESTPath()
    var requestIndicatesActivity: Bool
    var response: Either<[String: String], Error>
    
    init(requestIndicatesActivity: Bool, response: Either<[String: String], Error>) {
        self.requestIndicatesActivity = requestIndicatesActivity
        self.response = response
    }
    
    func handle(payload: [String: String]) throws -> [String: String] {
        return try response.dematerialize()
    }
}
