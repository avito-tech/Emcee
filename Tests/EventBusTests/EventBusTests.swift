import EventBus
import Foundation
import Models
import SynchronousWaiter
import XCTest

final class EventBusTest: XCTestCase {
    func testBroadcastingTestingResults() throws {
        let bus = EventBus()
        let stream = Listener()
        bus.add(stream: stream)
        let testingResult = TestingResult(
            bucket: Bucket(
                bucketId: "bucketid", testEntries: [],
                testDestination: try TestDestination(deviceType: "dvc", iOSVersion: "11.3")),
            successfulTests: [],
            failedTests: [],
            unfilteredTestRuns: [])
        
        bus.post(event: .didObtainTestingResult(testingResult))
        
        try SynchronousWaiter.waitWhile(timeout: 5.0, description: "Waiting for event bus to deliver events") {
            stream.testingResults.count == 0
        }
        
        XCTAssertEqual(stream.testingResults[0].bucket, testingResult.bucket)
    }
    
    func testBroadcastingTearDown() throws {
        let bus = EventBus()
        let stream = Listener()
        bus.add(stream: stream)
        bus.post(event: .tearDown)
        
        try SynchronousWaiter.waitWhile(timeout: 5.0, description: "Waiting for event bus to deliver events") {
            stream.didTearDown == nil
        }
        
        XCTAssertTrue(stream.didTearDown == true)
    }
}

private final class Listener: DefaultBusListener {
    public var testingResults = [TestingResult]()
    public var didTearDown: Bool?
    override func didObtain(testingResult: TestingResult) {
        testingResults.append(testingResult)
    }
    override func tearDown() {
        didTearDown = true
    }
}