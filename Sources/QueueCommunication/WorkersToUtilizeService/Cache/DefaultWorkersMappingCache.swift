import DateProvider
import Foundation
import EmceeLogging

private struct CacheData {
    let mapping: WorkersPerQueue
    let creationDate: Date
}

public class DefaultWorkersMappingCache: WorkersMappingCache {
    private let cacheIvalidationTime: TimeInterval
    private var cache: CacheData?
    private let dateProvider: DateProvider
    private let logger: ContextualLogger
    
    public init(
        cacheIvalidationTime: TimeInterval,
        dateProvider: DateProvider,
        logger: ContextualLogger
    ) {
        self.cacheIvalidationTime = cacheIvalidationTime
        self.dateProvider = dateProvider
        self.logger = logger
    }
    
    public func cachedMapping() -> WorkersPerQueue? {
        guard let cache = self.cache else {
            return nil
        }
        
        let timeSinceCacheCreation = dateProvider.currentDate().timeIntervalSince(cache.creationDate)
        
        if timeSinceCacheCreation >= cacheIvalidationTime {
            logger.debug("Invalidating workers mapping cache, time since cache creation: \(timeSinceCacheCreation)")
            self.cache = nil
        }
        
        return self.cache?.mapping
    }
    
    public func cache(mapping: WorkersPerQueue) {
        logger.debug("Caching workers mapping: \(mapping)")
        self.cache = CacheData(
            mapping: mapping,
            creationDate: dateProvider.currentDate()
        )
    }
}
