import Dispatch
import Foundation
import PathLib
import SynchronousWaiter
import TestHelpers
import URLResource
import XCTest

final class BlockingURLResourceHandlerTests: XCTestCase {
    private let runnerQueue = DispatchQueue(label: "runnerQueue", attributes: .concurrent)
    private let impactQueue = DispatchQueue(label: "impactQueue")
    private let remoteUrl = URL(string: "http://example.com")!
    private let resultingPath = AbsolutePath("/tmp/result/path")

    func test___provides_back_result() {
        let handler = BlockingURLResourceHandler()

        runnerQueue.async {
            let result = assertDoesNotThrow {
                try handler.wait(
                    limit: 60,
                    remoteUrl: self.remoteUrl
                )
            }
            XCTAssertEqual(result, self.resultingPath)
        }

        impactQueue.async {
            handler.resource(path: self.resultingPath, forUrl: self.remoteUrl)
        }

        runnerQueue.sync(flags: .barrier, execute: {})
    }

    func test___provides_back_error() {
        let handler = BlockingURLResourceHandler()

        runnerQueue.async {
            assertThrows {
                try handler.wait(
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
