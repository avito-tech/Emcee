@testable import QueueCommunication
import Models
import QueueCommunicationTestHelpers
import RequestSenderTestHelpers
import RESTMethods
import XCTest

import RemotePortDeterminer

class QueueCommunicationServiceTests: XCTestCase {
    let requestSender = FakeRequestSender()
    lazy var requestSenderProvider = FakeRequestSenderProvider(requestSender: requestSender)
    let remoteQueueDetector = FakeRemoteQueueDetector()
    
    lazy var service = DefaultQueueCommunicationService(
        remoteQueueDetector: remoteQueueDetector,
        requestSenderProvider: requestSenderProvider,
        requestTimeout: 10,
        socketHost: "host",
        version: "Version"
    )
        
    
    func test___workersToUtilize___return_error_if_no_master_queue_found() {
        remoteQueueDetector.shoudThrow = true
        let completionCalled = expectation(description: "Completion is called")
        
        service.workersToUtilize(deployments: []) { result in
            XCTAssert(result.isError)
            completionCalled.fulfill()
        }
        
        wait(for: [completionCalled], timeout: 10)
    }
    
    func test___workersToUtilize___return_error_if_request_is_failed() {
        remoteQueueDetector.masterPort = 1337
        requestSender.requestSenderError = .noData
        let completionCalled = expectation(description: "Completion is called")
        
        service.workersToUtilize(deployments: []) { result in
            XCTAssert(result.isError)
            completionCalled.fulfill()
        }
        
        XCTAssertEqual(requestSenderProvider.receivedSocketAddress, SocketAddress(host: "host", port: 1337))
        wait(for: [completionCalled], timeout: 10)
    }
    
    func test___workersToUtilize___return_worker_ids_if_request_is_successfull() {
        remoteQueueDetector.masterPort = 1337
        let expectedWorkerId: Set<WorkerId> = [
            WorkerId(value: "1"),
            WorkerId(value: "2"),
            WorkerId(value: "3")
        ]
        requestSender.result = WorkersToUtilizeResponse.workersToUtilize(workerIds: expectedWorkerId)
        let completionCalled = expectation(description: "Completion is called")
        
        service.workersToUtilize(deployments: []) { result in
            XCTAssertEqual(
                 try? result.dematerialize(),
                 expectedWorkerId
            )
            completionCalled.fulfill()
        }
        
        XCTAssertEqual(requestSenderProvider.receivedSocketAddress, SocketAddress(host: "host", port: 1337))
        wait(for: [completionCalled], timeout: 10)
    }
}
