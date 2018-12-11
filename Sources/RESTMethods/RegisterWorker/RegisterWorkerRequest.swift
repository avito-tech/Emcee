import Foundation

public final class RegisterWorkerRequest: Codable {
    public let workerId: String
    
    public init(workerId: String) {
        self.workerId = workerId
    }
}
