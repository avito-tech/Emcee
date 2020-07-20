import Extensions
import Foundation
import Models
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer

public final class QueueServerVersionEndpoint: RESTEndpoint {
    private let emceeVersion: Version
    private let queueServerLock: QueueServerLock
    public let path: RESTPath = RESTMethod.queueVersion
    public let requestIndicatesActivity = false
    
    public init(emceeVersion: Version, queueServerLock: QueueServerLock) {
        self.emceeVersion = emceeVersion
        self.queueServerLock = queueServerLock
    }
    
    public func handle(payload: QueueVersionPayload) throws -> QueueVersionResponse {
        guard queueServerLock.isDiscoverable else {
            return .queueVersion(Version(value: "not_discoverable_" + emceeVersion.value))
        }
        return .queueVersion(emceeVersion)
    }
}
