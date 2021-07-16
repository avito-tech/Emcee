import DateProvider
import DateProviderTestHelpers
import QueueCommunication
import QueueModels
import SocketModels
import XCTest

class WorkersMappingCacheTests: XCTestCase {
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    
    func test___default_mappings_is_nil() {
        let cache = DefaultWorkersMappingCache(cacheIvalidationTime: 0, dateProvider: dateProvider, logger: .noOp)
        XCTAssertNil(cache.cachedMapping())
    }
    
    func test___return_cached_mapping() {
        let expectedMapping: WorkersPerQueue = [
            QueueInfo(
                queueAddress: SocketAddress(host: "host", port: 12),
                queueVersion: "Version"
            ): ["WorkerId"]
        ]
        let cache = DefaultWorkersMappingCache(cacheIvalidationTime: 10, dateProvider: dateProvider, logger: .noOp)
        cache.cache(mapping: expectedMapping)
        
        let cachedMapping = cache.cachedMapping()
        
        XCTAssertEqual(cachedMapping, expectedMapping)
    }
    
    func test___invalidate_cached_mapping() {
        let expectedMapping: WorkersPerQueue = [
            QueueInfo(
                queueAddress: SocketAddress(host: "host", port: 12),
                queueVersion: "Version"
            ): ["WorkerId"]
        ]
        
        let cache = DefaultWorkersMappingCache(cacheIvalidationTime: 10, dateProvider: dateProvider, logger: .noOp)
        cache.cache(mapping: expectedMapping)
        
        dateProvider.result += 100
        
        let cachedMapping = cache.cachedMapping()
        
        XCTAssertNil(cachedMapping)
    }
}
