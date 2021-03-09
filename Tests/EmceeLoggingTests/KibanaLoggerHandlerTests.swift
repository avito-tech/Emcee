import EmceeLogging
import Foundation
import Kibana
import Logging
import TestHelpers
import XCTest

final class KibanaLoggerHandlerTests: XCTestCase {
    lazy var kibanaClient = FakeKibanaClient()
    lazy var handler = KibanaLoggerHandler(kibanaClient: kibanaClient)
    
    func test() {
        handler.log(
            level: .info,
            message: "hello",
            metadata: [
                "some": "data"
            ],
            source: "source",
            file: "file",
            function: "func",
            line: 42
        )
        
        let event = kibanaClient.capturedEvents[0]
        
        assertTrue { event.level == "info" }
        assertTrue { event.message == "hello" }
        assert {
            event.metadata
        } equals: {
            [
                "some": "data",
                "fileLine": "file:42",
            ]
        }

    }
    
    func test___waits_for_completions_after_tear_down() {
        handler.log(
            level: .info,
            message: "hello",
            metadata: [
                "some": "data"
            ],
            source: "source",
            file: "file",
            function: "func",
            line: 42
        )
        
        let event = kibanaClient.capturedEvents[0]
        
        let completionInvoked = XCTestExpectation(description: "")
        
        let impactQueue = DispatchQueue(label: "impactQueue")
        impactQueue.asyncAfter(deadline: .now() + 0.05) {
            event.completion(nil)
            completionInvoked.fulfill()
        }
        
        handler.tearDownLogging(timeout: 15)
        wait(for: [completionInvoked], timeout: 0)
    }
}

