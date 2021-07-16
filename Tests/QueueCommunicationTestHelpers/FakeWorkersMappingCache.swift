import QueueCommunication

public class FakeWorkersMappingCache: WorkersMappingCache {
    public init() { }
    
    public var presetCachedMapping: WorkersPerQueue?
    public func cachedMapping() -> WorkersPerQueue? {
        return presetCachedMapping
    }
    
    public var cacheMappingArgument: WorkersPerQueue?
    public func cache(mapping: WorkersPerQueue) {
        cacheMappingArgument = mapping
    }
}
