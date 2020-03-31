import RequestSender
import Models

public class DefaultRuntimeDumpRemoteCacheProvider: RuntimeDumpRemoteCacheProvider {
    private let senderProvider: RequestSenderProvider
    public init(senderProvider: RequestSenderProvider) {
        self.senderProvider = senderProvider
    }

    public func remoteCache(config: RuntimeDumpRemoteCacheConfig?) -> RuntimeDumpRemoteCache {
        guard let config = config else {
            return NoOpRuntimeDumpRemoteCache()
        }

        return DefaultRuntimeDumpRemoteCache(
            config: config,
            sender: senderProvider.requestSender(socketAddress: config.socketAddress)
        )
    }
}
