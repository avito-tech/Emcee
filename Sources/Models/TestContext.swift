import Foundation

public final class TestContext: Codable {
    public let environment: [String: String]
    
    public init(environment: [String: String]) {
        self.environment = environment
    }
}
