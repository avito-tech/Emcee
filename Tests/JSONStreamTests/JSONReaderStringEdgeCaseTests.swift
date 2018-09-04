import Foundation
import JSONStream
import XCTest

class JSONReaderStringEdgeCaseTests: XCTestCase {
    
    var eventStream = FakeEventStream()
    override func setUp() {
        eventStream = FakeEventStream()
    }
        
    func testInputWithEscapedSymbols() throws {
        let jsonStream = FakeJSONStream(string: "{ \"key\": \"__\\\"hello world\\\"__\" }")
        let reader = JSONReader(inputStream: jsonStream, eventStream: eventStream)
        try reader.start()
        
        XCTAssertEqual(eventStream.all.count, 1)
        XCTAssertEqual(eventStream.allObjects[0], ["key": "__\\\"hello world\\\"__"])
    }
}
