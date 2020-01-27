import Extensions
import FileHasher
import Foundation
import QueueServer
import RESTMethods
import VersionTestHelpers
import XCTest

final class QueueServerVersionEndpointTests: XCTestCase {
    
    func test___endpoint_hashes_main_binary() throws {
        let endpoint = QueueServerVersionEndpoint(
            queueServerLock: NeverLockableQueueServerLock(),
            versionProvider: VersionProviderFixture().with(predefinedVersion: "version").buildVersionProvider()
        )
        let actualResult = try endpoint.handle(decodedPayload: QueueVersionPayload())
        XCTAssertEqual(QueueVersionResponse.queueVersion("version"), actualResult)
    }
    
    func test___when_locked___endpoint_provides_modified_version() throws {
        let endpoint = QueueServerVersionEndpoint(
            queueServerLock: AlwaysLockedQueueServerLock(),
            versionProvider: VersionProviderFixture().with(predefinedVersion: "version").buildVersionProvider()
        )
        let actualResult = try endpoint.handle(decodedPayload: QueueVersionPayload())
        XCTAssertEqual(QueueVersionResponse.queueVersion("not_discoverable_version"), actualResult)
    }
}

class AlwaysLockedQueueServerLock: QueueServerLock {
    let isDiscoverable = false
    
    public init() {}
}
