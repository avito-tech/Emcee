import Extensions
import Foundation
import Models
import RESTMethods

public final class QueueServerVersionEndpoint: RESTEndpoint {
    private let versionProvider: () throws -> String
    
    public init(versionProvider: @escaping () throws -> String) {
        self.versionProvider = versionProvider
    }
    
    public func handle(decodedRequest: QueueVersionRequest) throws -> QueueVersionResponse {
        return .queueVersion(try versionProvider())
    }
}
