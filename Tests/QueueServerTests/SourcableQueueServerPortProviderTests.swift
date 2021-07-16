import QueueServer
import QueueServerTestHelpers
import QueueServerPortProvider
import QueueServerPortProviderTestHelpers
import TestHelpers
import XCTest

final class SourcableQueueServerPortProviderTests: XCTestCase {
    lazy var provider = SourcableQueueServerPortProvider()
    
    func test___throws_when_source_not_set() {
        assertThrows {
            try provider.port()
        }
    }
    
    func test___provides_from_source() {
        let source = FakeQueueServerPortProvider(port: 42)
        
        provider.source = source
        
        XCTAssertEqual(
            try provider.port(),
            42
        )
    }
}

