@testable import QueueCommunication
import QueueCommunicationTestHelpers
import QueueModels
import RESTMethods
import RemotePortDeterminer
import RequestSenderTestHelpers
import SocketModels
import XCTest

class QueueCommunicationServiceTests: XCTestCase {
    lazy var requestSender = FakeRequestSender()
    lazy var requestSenderProvider = FakeRequestSenderProvider(requestSender: requestSender)
    lazy var remoteQueueDetector = FakeRemoteQueueDetector()
    lazy var queueInfo = QueueInfo(
        queueAddress: SocketAddress(host: "host", port: 42),
        queueVersion: "Version"
    )
    lazy var service = DefaultQueueCommunicationService(
        logger: .noOp,
        remoteQueueDetector: remoteQueueDetector,
        requestSenderProvider: requestSenderProvider,
        requestTimeout: 10
    )
    
    func test___workersToUtilize___return_error_if_no_master_queue_found() {
        remoteQueueDetector.shoudThrow = true
        let completionCalled = expectation(description: "Completion is called")
        
        service.workersToUtilize(queueInfo: queueInfo, workerIds: []) { result in
            XCTAssert(result.isError)
            completionCalled.fulfill()
        }
        
        wait(for: [completionCalled], timeout: 10)
    }
    
    func test___workersToUtilize___return_error_if_request_is_failed() {
        remoteQueueDetector.masterAddress = SocketAddress(host: "host", port: 1337)
        requestSender.requestSenderError = .noData
        let completionCalled = expectation(description: "Completion is called")
        
        service.workersToUtilize(queueInfo: queueInfo, workerIds: []) { result in
            XCTAssert(result.isError)
            completionCalled.fulfill()
        }
        
        XCTAssertEqual(requestSenderProvider.receivedSocketAddress, SocketAddress(host: "host", port: 1337))
        wait(for: [completionCalled], timeout: 10)
    }
    
    func test___workersToUtilize___return_worker_ids_if_request_is_successfull() {
        remoteQueueDetector.masterAddress = SocketAddress(host: "host", port: 1337)
        let expectedWorkerId: Set<WorkerId> = [
            WorkerId(value: "1"),
            WorkerId(value: "2"),
            WorkerId(value: "3")
        ]
        requestSender.result = WorkersToUtilizeResponse.workersToUtilize(workerIds: expectedWorkerId)
        let completionCalled = expectation(description: "Completion is called")
        
        service.workersToUtilize(queueInfo: queueInfo, workerIds: []) { result in
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
