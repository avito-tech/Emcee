import Extensions
import FileHasher
import Foundation
import Models
import RESTMethods

public final class QueueServerVersionEndpoint: RESTEndpoint {
    public init() {}
    
    private let hasher = FileHasher(fileUrl: URL(fileURLWithPath: ProcessInfo.processInfo.executablePath))
    
    public func handle(decodedRequest: QueueVersionRequest) throws -> QueueVersionResponse {
        return .queueVersion(try hasher.hash())
    }
}
