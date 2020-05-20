import Extensions
import Foundation
import QueueServer
import RESTMethods
import XCTest

final class QueueServerVersionEndpointTests: XCTestCase {
    
    func test___endpoint_hashes_main_binary() throws {
        let endpoint = QueueServerVersionEndpoint(
            emceeVersion: "version",
            queueServerLock: NeverLockableQueueServerLock()
        )
        let actualResult = try endpoint.handle(payload: QueueVersionPayload())
        XCTAssertEqual(QueueVersionResponse.queueVersion("version"), actualResult)
    }
    
    func test___when_locked___endpoint_provides_modified_version() throws {
        let endpoint = QueueServerVersionEndpoint(
            emceeVersion: "version",
            queueServerLock: AlwaysLockedQueueServerLock()
        )
        let actualResult = try endpoint.handle(payload: QueueVersionPayload())
        XCTAssertEqual(QueueVersionResponse.queueVersion("not_discoverable_version"), actualResult)
    }
    
    func test___does_not_indicate_activity() {
        let endpoint = QueueServerVersionEndpoint(
            emceeVersion: "version",
            queueServerLock: NeverLockableQueueServerLock()
        )
        
        XCTAssertFalse(
            endpoint.requestIndicatesActivity,
            "This endpoint should not indicate activity because queue server version is being checked for various discovery purposes"
        )
    }
}

class AlwaysLockedQueueServerLock: QueueServerLock {
    let isDiscoverable = false
    
    public init() {}
}
