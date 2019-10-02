import Foundation
import Models
import QueueClient
import RESTMethods
import RequestSender
import RequestSenderTestHelpers
import Version
import XCTest

final class QueueServerVersionFetcherTests: XCTestCase {
    private let version = Version(value: "version")
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    
    func test() throws {
        let requestSender = FakeRequestSender(
            result: QueueVersionResponse.queueVersion(version),
            requestSenderError: nil
        )
        
        let fetcher = QueueServerVersionFetcherImpl(
            requestSender: requestSender
        )
    
        let completionHandlerCalledExpectation = expectation(description: "Completion handler has been called")
        fetcher.fetchQueueServerVersion(
            callbackQueue: callbackQueue
        ) { (result: Either<Version, Error>) in
            XCTAssertEqual(
                try? result.dematerialize(),
                self.version
            )
            completionHandlerCalledExpectation.fulfill()
        }
        
        wait(for: [completionHandlerCalledExpectation], timeout: 10)
    }
}

