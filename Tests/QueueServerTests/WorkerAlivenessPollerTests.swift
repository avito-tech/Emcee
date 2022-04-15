//import AtomicModels
//import DistWorkerModels
//import Foundation
//import QueueCommunicationTestHelpers
//import QueueModels
//import QueueServer
//import QueueServerTestHelpers
//import RequestSender
//import RequestSenderTestHelpers
//import SocketModels
//import SynchronousWaiter
//import TestHelpers
//import WorkerAlivenessModels
//import WorkerAlivenessProvider
//import XCTest
//
//final class WorkerAlivenessPollerTests: XCTestCase {
//    lazy var bucketId1 = BucketId(value: "bucketId1")
//    lazy var worker1 = WorkerId("worker1")
//    lazy var worker2 = WorkerId("worker2")
//    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
//        logger: .noOp,
//        workerPermissionProvider: FakeWorkerPermissionProvider()
//    )
//    lazy var workerDetailsHolder = WorkerDetailsHolderImpl()
//    
//    func test___querying_worker_state___updates_worker_aliveness_provider() {
//        workerAlivenessProvider.didRegisterWorker(workerId: worker1)
//        workerDetailsHolder.update(workerId: worker1, restAddress: SocketAddress(host: "host1", port: 42))
//        
//        let requestSenderHasBeenUsedToQueryWorker1 = XCTestExpectation(description: "\(worker1) has been queried")
//        
//        let requestSenderProvider = FakeRequestSenderProvider { [bucketId1] socketAddress -> RequestSender in
//            XCTAssertEqual(socketAddress, SocketAddress(host: "host1", port: 42))
//            
//            let requestSender = FakeRequestSender()
//            
//            requestSender.validateRequest = { aRequestSender in
//                guard aRequestSender.request is CurrentlyProcessingBucketsNetworkRequest else {
//                    return XCTFail("Unexpected request has been sent: \(String(describing: aRequestSender.request))")
//                }
//                aRequestSender.result = CurrentlyProcessingBucketsResponse(bucketIds: [bucketId1])
//            }
//            
//            requestSender.requestCompleted = {
//                _ in requestSenderHasBeenUsedToQueryWorker1.fulfill()
//            }
//            return requestSender
//        }
//        
//        XCTAssertEqual(
//            workerAlivenessProvider.alivenessForWorker(workerId: worker1),
//            WorkerAliveness(registered: true, bucketIdsBeingProcessed: [], disabled: false, silent: false, workerUtilizationPermission: .allowedToUtilize)
//        )
//        
//        let poller = createWorkerAlivenessPoller(requestSenderProvider: requestSenderProvider)
//        defer { poller.stopPolling() }
//        poller.startPolling()
//        
//        wait(for: [requestSenderHasBeenUsedToQueryWorker1], timeout: 15)
//        
//        XCTAssertEqual(
//            workerAlivenessProvider.alivenessForWorker(workerId: worker1),
//            WorkerAliveness(registered: true, bucketIdsBeingProcessed: [bucketId1], disabled: false, silent: false, workerUtilizationPermission: .allowedToUtilize)
//        )
//    }
//    
//    func test___when_worker_does_not_respond_in_time___aliveness_not_updated() {
//        workerAlivenessProvider.didRegisterWorker(workerId: worker1)
//        workerAlivenessProvider.didRegisterWorker(workerId: worker2)
//        workerDetailsHolder.update(workerId: worker1, restAddress: SocketAddress(host: "host1", port: 0))
//        
//        let requestSenderHasBeenUsedToQueryWorker1 = XCTestExpectation(description: "\(worker1) has been queried")
//        
//        let requestSenderProvider = FakeRequestSenderProvider { socketAddress -> RequestSender in
//            let requestSender = FakeRequestSender()
//            requestSender.requestCompleted = { _ in
//                requestSenderHasBeenUsedToQueryWorker1.fulfill()
//            }
//            return requestSender
//        }
//        
//        let poller = createWorkerAlivenessPoller(requestSenderProvider: requestSenderProvider)
//        defer { poller.stopPolling() }
//        poller.startPolling()
//        
//        wait(for: [requestSenderHasBeenUsedToQueryWorker1], timeout: 15)
//        
//        XCTAssertEqual(
//            workerAlivenessProvider.alivenessForWorker(workerId: worker1),
//            WorkerAliveness(registered: true, bucketIdsBeingProcessed: [], disabled: false, silent: false, workerUtilizationPermission: .allowedToUtilize)
//        )
//        XCTAssertEqual(
//            workerAlivenessProvider.alivenessForWorker(workerId: worker2),
//            WorkerAliveness(registered: true, bucketIdsBeingProcessed: [], disabled: false, silent: false, workerUtilizationPermission: .allowedToUtilize)
//        )
//    }
//    
//    func test___querying_multiple_workers() {
//        workerDetailsHolder.update(workerId: worker1, restAddress: SocketAddress(host: "host1", port: 42))
//        workerDetailsHolder.update(workerId: worker2, restAddress: SocketAddress(host: "host2", port: 24))
//        
//        let requestSenderHasBeenUsedToQueryWorker1 = XCTestExpectation(description: "\(worker1) has been queried")
//        let requestSenderHasBeenUsedToQueryWorker2 = XCTestExpectation(description: "\(worker2) has been queried")
//        
//        let requestSenderProvider = FakeRequestSenderProvider { socketAddress -> RequestSender in
//            let requestSender = FakeRequestSender()
//            requestSender.requestCompleted = { _ in
//                if socketAddress == SocketAddress(host: "host1", port: 42) {
//                    requestSenderHasBeenUsedToQueryWorker1.fulfill()
//                } else if socketAddress == SocketAddress(host: "host2", port: 24) {
//                    requestSenderHasBeenUsedToQueryWorker2.fulfill()
//                } else {
//                    XCTFail("Unexpected request to \(socketAddress)")
//                }
//            }
//            return requestSender
//        }
//        
//        let poller = createWorkerAlivenessPoller(requestSenderProvider: requestSenderProvider)
//        defer { poller.stopPolling() }
//        poller.startPolling()
//        
//        wait(for: [requestSenderHasBeenUsedToQueryWorker1, requestSenderHasBeenUsedToQueryWorker2], timeout: 15)
//    }
//    
//    func test___querying_load_of_workers() {
//        let numberOfWorkers = 256
//        let numberOfProcessedRequests = AtomicValue<Int>(0)
//        
//        let server = HttpServer()
//        assertDoesNotThrow { try server.start(0) }
//        let port = assertDoesNotThrow { try server.port() }
//        
//        for i in 0 ..< numberOfWorkers {
//            workerDetailsHolder.update(
//                workerId: WorkerId(value: "worker__\(i)"),
//                restAddress: SocketAddress(host: "localhost", port: Port(value: port))
//            )
//            server[CurrentlyProcessingBuckets.path.pathWithLeadingSlash] = { request in
//                numberOfProcessedRequests.withExclusiveAccess { $0 += 1 }
//                return HttpResponse.json(response: CurrentlyProcessingBucketsResponse(bucketIds: []))
//            }
//        }
//        
//        let poller = createWorkerAlivenessPoller(
//            requestSenderProvider: DefaultRequestSenderProvider(logger: .noOp)
//        )
//        defer { poller.stopPolling() }
//        poller.startPolling()
//        
//        assertDoesNotThrow {
//            try SynchronousWaiter().waitWhile(pollPeriod: 0.3, timeout: Timeout(description: "requests have been processed", value: 20)) {
//                numberOfProcessedRequests.currentValue() < numberOfWorkers
//            }
//        }
//    }
//    
//    private func createWorkerAlivenessPoller(
//        pollInterval: TimeInterval = 12,
//        requestSenderProvider: RequestSenderProvider
//    ) -> WorkerAlivenessPoller {
//        return WorkerAlivenessPoller(
//            logger: .noOp,
//            pollInterval: pollInterval,
//            requestSenderProvider: requestSenderProvider,
//            workerAlivenessProvider: workerAlivenessProvider,
//            workerDetailsHolder: workerDetailsHolder
//        )
//    }
//}
