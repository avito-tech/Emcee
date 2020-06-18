import DateProvider
import Foundation
import Logging

private struct CacheData {
    let mapping: WorkersPerVersion
    let creationDate: Date
}

public class DefaultWorkersMappingCache: WorkersMappingCache {
    private let cacheIvalidationTime: TimeInterval
    private var cache: CacheData?
    private let dateProvider: DateProvider
    public init(
        cacheIvalidationTime: TimeInterval,
        dateProvider: DateProvider
    ) {
        self.cacheIvalidationTime = cacheIvalidationTime
        self.dateProvider = dateProvider
    }
    
    public func cachedMapping() -> WorkersPerVersion? {
        guard let cache = self.cache else {
            return nil
        }
        
        let timeSinceCacheCreation = Date().timeIntervalSince(cache.creationDate)
        
        if TimeInterval(timeSinceCacheCreation) >= cacheIvalidationTime {
            Logger.info("Invalidating workers mapping cache, time since cache creation: \(timeSinceCacheCreation)")
            self.cache = nil
        }
        
        return self.cache?.mapping
    }
    
    public func cacheMapping(_ mapping: WorkersPerVersion) {
        Logger.info("Caching workers mapping: \(mapping)")
        self.cache = CacheData(
            mapping: mapping,
            creationDate: dateProvider.currentDate()
        )
    }
}
