import Foundation
import Models
import RESTMethods
import RequestSender
import RequestSenderTestHelpers
import QueueClient
import XCTest
import ModelsTestHelpers

final class WorkerRegistererImplTests: XCTestCase {
    private let workerId = WorkerId(value: "workerId")
    
    func test() throws {
        let workerConfiguration = WorkerConfigurationFixtures.workerConfiguration
        let requestSender = FakeRequestSender(
            result: RegisterWorkerResponse.workerRegisterSuccess(workerConfiguration: workerConfiguration),
            requestSenderError: nil
        )
        let workerRegisterer = WorkerRegistererImpl(
            requestSender: requestSender
        )
        
        let expectation = self.expectation(description: "registerWithServer completion is called")
        
        var result: Either<WorkerConfiguration, RequestSenderError>?
        
        try workerRegisterer.registerWithServer(workerId: workerId) { localResult in
            result = localResult
            expectation.fulfill()
        }
        
        XCTAssertEqual(
            try result?.dematerialize(),
            workerConfiguration,
            "Response should have the provided worker configuration"
        )
        
        wait(for: [expectation], timeout: 10)
    }
}

