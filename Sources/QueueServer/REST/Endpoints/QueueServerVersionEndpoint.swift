import Extensions
import Foundation
import Models
import RESTMethods
import Version

public final class QueueServerVersionEndpoint: RESTEndpoint {
    private let versionProvider: VersionProvider
    
    public init(versionProvider: VersionProvider) {
        self.versionProvider = versionProvider
    }
    
    public func handle(decodedRequest: QueueVersionRequest) throws -> QueueVersionResponse {
        return .queueVersion(try versionProvider.version())
    }
}
