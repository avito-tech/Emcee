import Extensions
import Foundation
import Models
import RESTMethods
import RESTServer

public final class QueueServerVersionEndpoint: RESTEndpoint {
    private let emceeVersion: Version
    private let queueServerLock: QueueServerLock
    
    public init(emceeVersion: Version, queueServerLock: QueueServerLock) {
        self.emceeVersion = emceeVersion
        self.queueServerLock = queueServerLock
    }
    
    public func handle(decodedPayload: QueueVersionPayload) throws -> QueueVersionResponse {
        guard queueServerLock.isDiscoverable else {
            return .queueVersion(Version(value: "not_discoverable_" + emceeVersion.value))
        }
        return .queueVersion(emceeVersion)
    }
}
