import Foundation
import Models

public final class DequeueBucketRequest: Codable {
    public let workerId: String
    public let requestId: String
    
    public init(workerId: String, requestId: String) {
        self.workerId = workerId
        self.requestId = requestId
    }
}
