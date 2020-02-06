import Models

public protocol RuntimeDumpRemoteCacheProvider {
    func remoteCache(config: RuntimeDumpRemoteCacheConfig?) -> RuntimeDumpRemoteCache
}
