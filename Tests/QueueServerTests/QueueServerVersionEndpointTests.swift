import Extensions
import FileHasher
import Foundation
import QueueServer
import RESTMethods
import VersionTestHelpers
import XCTest

final class QueueServerVersionEndpointTests: XCTestCase {
    
    func test___endpoint_hashes_main_binary() throws {
        let endpoint = QueueServerVersionEndpoint(versionProvider: VersionProviderFixture().with(predefinedVersion: "version").buildVersionProvider())
        let actualResult = try endpoint.handle(decodedRequest: QueueVersionRequest())
        XCTAssertEqual(QueueVersionResponse.queueVersion("version"), actualResult)
    }
}

