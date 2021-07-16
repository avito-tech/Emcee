public protocol WorkersMappingCache {
    func cachedMapping() -> WorkersPerQueue?
    func cache(mapping: WorkersPerQueue)
}
