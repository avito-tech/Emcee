import Foundation
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import Types
import WorkerAlivenessModels
import XCTest

final class WorkerStatusFetcherTests: XCTestCase {
    private lazy var workerAliveness = WorkerAliveness(
        registered: true,
        bucketIdsBeingProcessed: [],
        disabled: false,
        silent: true,
        workerUtilizationPermission: .allowedToUtilize
    )
    private lazy var workerId = WorkerId(value: "worker")
    private lazy var callbackQueue = DispatchQueue(label: "callbackQueue")
    
    func test() throws {
        let requestSender = FakeRequestSender(
            result: WorkerStatusResponse(workerAliveness: [workerId: workerAliveness]),
            requestSenderError: nil
        )
        
        let fetcher = WorkerStatusFetcherImpl(
            requestSender: requestSender
        )
    
        let completionHandlerCalledExpectation = expectation(description: "Completion handler has been called")
        
        fetcher.fetch(
            callbackQueue: callbackQueue
        ) { (result: Either<[WorkerId: WorkerAliveness], Error>) in
            XCTAssertEqual(
                try? result.dematerialize(),
                [self.workerId: self.workerAliveness]
            )
            completionHandlerCalledExpectation.fulfill()
        }
        
        wait(for: [completionHandlerCalledExpectation], timeout: 10)
    }
}
