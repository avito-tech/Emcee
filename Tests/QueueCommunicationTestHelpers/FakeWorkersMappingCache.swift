import QueueCommunication

public class FakeWorkersMappingCache: WorkersMappingCache {
    public init() { }
    
    public var presetCachedMapping: WorkersPerVersion?
    public func cachedMapping() -> WorkersPerVersion? {
        return presetCachedMapping
    }
    
    public var cacheMappingArgument: WorkersPerVersion?
    public func cache(mapping: WorkersPerVersion) {
        cacheMappingArgument = mapping
    }
}
