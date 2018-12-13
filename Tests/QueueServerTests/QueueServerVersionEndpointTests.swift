import Extensions
import FileHasher
import Foundation
import QueueServer
import RESTMethods
import XCTest

final class QueueServerVersionEndpointTests: XCTestCase {
    
    func test___endpoint_hashes_main_binary() throws {
        let endpoint = QueueServerVersionEndpoint(versionProvider: { "version" })
        let actualResult = try endpoint.handle(decodedRequest: QueueVersionRequest())
        XCTAssertEqual(QueueVersionResponse.queueVersion("version"), actualResult)
    }
}

