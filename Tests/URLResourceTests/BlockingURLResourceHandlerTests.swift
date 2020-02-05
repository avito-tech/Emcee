import Dispatch
import Foundation
import SynchronousWaiter
import TestHelpers
import URLResource
import XCTest

final class BlockingURLResourceHandlerTests: XCTestCase {
    private let waiter = SynchronousWaiter()
    private let runnerQueue = DispatchQueue(label: "runnerQueue", attributes: .concurrent)
    private let impactQueue = DispatchQueue(label: "impactQueue")
    private let remoteUrl = URL(string: "http://example.com")!
    private let resultingUrl = URL(string: "http://result.com")!

    func test___provides_back_result() {
        let handler = BlockingURLResourceHandler(waiter: waiter)

        runnerQueue.async {
            let result = self.assertDoesNotThrow {
                try handler.wait(
                    limit: 60,
                    remoteUrl: self.remoteUrl
                )
            }
            XCTAssertEqual(result, self.resultingUrl)
        }

        impactQueue.async {
            handler.resourceUrl(contentUrl: self.resultingUrl, forUrl: self.remoteUrl)
        }

        runnerQueue.sync(flags: .barrier, execute: {})
    }

    func test___provides_back_error() {
        let handler = BlockingURLResourceHandler(waiter: waiter)

        runnerQueue.async {
            self.assertThrows {
                _ = try handler.wait(
                    limit: 60,
                    remoteUrl: self.remoteUrl
                )
            }
        }

        impactQueue.async {
            handler.failedToGetContents(
                forUrl: self.remoteUrl,
                error: ErrorForTestingPurposes(text: "sample error")
            )
        }

        runnerQueue.sync(flags: .barrier, execute: {})
    }
}
