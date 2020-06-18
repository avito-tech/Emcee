import DateProvider
import DateProviderTestHelpers
import QueueCommunication
import XCTest

class WorkersMappingCacheTests: XCTestCase {
    func test___default_mappings_is_nil() {
        let cache = DefaultWorkersMappingCache(cacheIvalidationTime: 0, dateProvider: SystemDateProvider())
        XCTAssertNil(cache.cachedMapping())
    }
    
    func test___return_cached_mapping() {
        let expectedMapping: WorkersPerVersion = ["Version": ["WorkerId"]]
        let cache = DefaultWorkersMappingCache(cacheIvalidationTime: 10, dateProvider: SystemDateProvider())
        cache.cacheMapping(expectedMapping)
        
        let cachedMapping = cache.cachedMapping()
        
        XCTAssertEqual(cachedMapping, expectedMapping)
    }
    
    func test___invalidate_cached_mapping() {
        let expectedMapping: WorkersPerVersion = ["Version": ["WorkerId"]]
        let date = Calendar.current.date(byAdding: DateComponents(minute: -1), to: Date())
        let dateProvider = DateProviderFixture(date!)
        let cache = DefaultWorkersMappingCache(cacheIvalidationTime: 10, dateProvider: dateProvider)
        cache.cacheMapping(expectedMapping)
        
        let cachedMapping = cache.cachedMapping()
        
        XCTAssertNil(cachedMapping)
    }
}
