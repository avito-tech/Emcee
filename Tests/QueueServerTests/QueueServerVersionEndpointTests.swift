import Extensions
import FileHasher
import Foundation
import QueueServer
import RESTMethods
import XCTest

final class QueueServerVersionEndpointTests: XCTestCase {
    
    let hasher = FileHasher(fileUrl: URL(fileURLWithPath: ProcessInfo.processInfo.executablePath))
    
    func test___endpoint_hashes_main_binary() throws {
        let endpoint = QueueServerVersionEndpoint()
        
        let expectedResult = try hasher.hash()
        let actualResult = try endpoint.handle(decodedRequest: QueueVersionRequest())
        
        XCTAssertEqual(QueueVersionResponse.queueVersion(expectedResult), actualResult)
    }
}

