public protocol WorkersMappingCache {
    func cachedMapping() -> WorkersPerVersion?
    func cacheMapping(_ mapping: WorkersPerVersion)
}
