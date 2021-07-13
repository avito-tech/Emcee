public protocol WorkersMappingCache {
    func cachedMapping() -> WorkersPerVersion?
    func cache(mapping: WorkersPerVersion)
}
