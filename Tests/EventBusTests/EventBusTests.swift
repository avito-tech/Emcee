import EventBus
import Foundation
import Models
import ModelsTestHelpers
import SynchronousWaiter
import XCTest

final class EventBusTest: XCTestCase {
    func testBroadcastingTearDown() throws {
        let bus = EventBus()
        let stream = Listener()
        bus.add(stream: stream)
        bus.tearDown()
        
        try SynchronousWaiter().waitWhile(timeout: 5.0, description: "Waiting for event bus to deliver events") {
            stream.didTearDown == nil
        }
        
        XCTAssertTrue(stream.didTearDown == true)
    }
}

private final class Listener: DefaultBusListener {
    public var didTearDown: Bool?
    override func tearDown() {
        didTearDown = true
    }
}
