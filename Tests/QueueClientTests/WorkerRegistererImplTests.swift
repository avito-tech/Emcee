import DistWorkerModels
import DistWorkerModelsTestHelpers
import Foundation
import QueueClient
import QueueModels
import RESTMethods
import RequestSender
import RequestSenderTestHelpers
import SocketModels
import Types
import XCTest

final class WorkerRegistererImplTests: XCTestCase {
    private let workerId = WorkerId(value: "workerId")
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    
    
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
        
        var result: Either<WorkerConfiguration, Error>?
        
        workerRegisterer.registerWithServer(
            workerId: workerId,
            workerCapabilities: [],
            workerRestAddress: SocketAddress(host: "host", port: 0),
            callbackQueue: callbackQueue
        ) { localResult in
            result = localResult
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
        
        XCTAssertEqual(
            try result?.dematerialize(),
            workerConfiguration,
            "Response should have the provided worker configuration"
        )
    }
}

