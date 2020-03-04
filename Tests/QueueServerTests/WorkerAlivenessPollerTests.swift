import DistWorkerModels
import Foundation
import Models
import QueueServer
import QueueServerTestHelpers
import RequestSender
import RequestSenderTestHelpers
import WorkerAlivenessProvider
import WorkerAlivenessProviderTestHelpers
import XCTest

final class WorkerAlivenessPollerTests: XCTestCase {
    let workerAlivenessProvider = MutableWorkerAlivenessProvider()
    let workerDetailsHolder = WorkerDetailsHolderImpl()
    let worker1 = WorkerId("worker1")
    let worker2 = WorkerId("worker2")
    let bucketId1 = BucketId(value: "bucketId1")
    
    func test___querying_worker_state___updates_worker_aliveness_provider() {
        workerDetailsHolder.update(workerId: worker1, restPort: 42)
        
        let requestSenderHasBeenUsedToQueryWorker1 = XCTestExpectation(description: "\(worker1) has been queried")
        
        let requestSenderProvider = FakeRequestSenderProvider { [worker1, bucketId1] socketAddress -> RequestSender in
            XCTAssertEqual(socketAddress, SocketAddress(host: worker1.value, port: 42))
            
            let requestSender = FakeRequestSender()
            
            requestSender.validateRequest = { aRequestSender in
                guard aRequestSender.request is CurrentlyProcessingBucketsNetworkRequest else {
                    return XCTFail("Unexpected request has been sent: \(String(describing: aRequestSender.request))")
                }
                aRequestSender.result = CurrentlyProcessingBucketsResponse(bucketIds: [bucketId1])
            }
            
            requestSender.requestCompleted = {
                _ in requestSenderHasBeenUsedToQueryWorker1.fulfill()
            }
            return requestSender
        }
        
        XCTAssertEqual(
            workerAlivenessProvider.alivenessForWorker(workerId: worker1),
            WorkerAliveness(status: .notRegistered, bucketIdsBeingProcessed: [])
        )
        
        let poller = createWorkerAlivenessPoller(requestSenderProvider: requestSenderProvider)
        defer { poller.stopPolling() }
        poller.startPolling()
        
        wait(for: [requestSenderHasBeenUsedToQueryWorker1], timeout: 15)
        
        XCTAssertEqual(
            workerAlivenessProvider.alivenessForWorker(workerId: worker1),
            WorkerAliveness(status: .alive, bucketIdsBeingProcessed: Set([bucketId1]))
        )
    }
    
    func test___when_worker_does_not_respond_in_time___aliveness_not_updated() {
        workerDetailsHolder.update(workerId: worker1, restPort: 42)
        
        let requestSenderHasBeenUsedToQueryWorker1 = XCTestExpectation(description: "\(worker1) has been queried")
        
        let requestSenderProvider = FakeRequestSenderProvider { socketAddress -> RequestSender in
            let requestSender = FakeRequestSender()
            requestSender.requestCompleted = {
                _ in requestSenderHasBeenUsedToQueryWorker1.fulfill()
            }
            return requestSender
        }
        
        let poller = createWorkerAlivenessPoller(requestSenderProvider: requestSenderProvider)
        defer { poller.stopPolling() }
        poller.startPolling()
        
        wait(for: [requestSenderHasBeenUsedToQueryWorker1], timeout: 15)
        
        XCTAssertEqual(
            workerAlivenessProvider.workerAliveness,
            [:]
        )
    }
    
    func test___querying_multiple_workers() {
        workerDetailsHolder.update(workerId: worker1, restPort: 42)
        workerDetailsHolder.update(workerId: worker2, restPort: 24)
        
        let requestSenderHasBeenUsedToQueryWorker1 = XCTestExpectation(description: "\(worker1) has been queried")
        let requestSenderHasBeenUsedToQueryWorker2 = XCTestExpectation(description: "\(worker2) has been queried")
        
        let requestSenderProvider = FakeRequestSenderProvider { [worker1, worker2] socketAddress -> RequestSender in
            let requestSender = FakeRequestSender()
            requestSender.requestCompleted = { _ in
                if socketAddress == SocketAddress(host: worker1.value, port: 42) {
                    requestSenderHasBeenUsedToQueryWorker1.fulfill()
                } else if socketAddress == SocketAddress(host: worker2.value, port: 24) {
                    requestSenderHasBeenUsedToQueryWorker2.fulfill()
                } else {
                    XCTFail("Unexpected request to \(socketAddress)")
                }
            }
            return requestSender
        }
        
        let poller = createWorkerAlivenessPoller(requestSenderProvider: requestSenderProvider)
        defer { poller.stopPolling() }
        poller.startPolling()
        
        wait(for: [requestSenderHasBeenUsedToQueryWorker1, requestSenderHasBeenUsedToQueryWorker2], timeout: 15)
    }
    
    private func createWorkerAlivenessPoller(
        pollInterval: TimeInterval = 12,
        requestSenderProvider: RequestSenderProvider
    ) -> WorkerAlivenessPoller {
        return WorkerAlivenessPoller(
            pollInterval: pollInterval,
            requestSenderProvider: requestSenderProvider,
            workerAlivenessProvider: workerAlivenessProvider,
            workerDetailsHolder: workerDetailsHolder
        )
    }
}
