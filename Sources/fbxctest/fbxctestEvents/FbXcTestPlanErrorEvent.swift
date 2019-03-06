import Foundation

public final class FbXcTestPlanErrorEvent: CustomStringConvertible, Decodable {
    public let event: FbXcTestEventName = .testPlanError
    public let message: String
    public let timestamp: TimeInterval = Date().timeIntervalSince1970
    
    public init(message: String) {
        self.message = message
    }
    
    public var description: String {
        return "Test plan failed with message: \(message)"
    }
}
