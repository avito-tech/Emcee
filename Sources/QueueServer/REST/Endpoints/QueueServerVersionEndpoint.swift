import Extensions
import Foundation
import Models
import RESTMethods
import Version

public final class QueueServerVersionEndpoint: RESTEndpoint {
    private let queueServerLock: QueueServerLock
    private let versionProvider: VersionProvider
    
    public init(queueServerLock: QueueServerLock, versionProvider: VersionProvider) {
        self.queueServerLock = queueServerLock
        self.versionProvider = versionProvider
    }
    
    public func handle(decodedRequest: QueueVersionRequest) throws -> QueueVersionResponse {
        let version = try versionProvider.version()
        guard queueServerLock.isDiscoverable else {
            return .queueVersion(Version(value: "not_discoverable_" + version.value))
        }
        return .queueVersion(version)
    }
}
