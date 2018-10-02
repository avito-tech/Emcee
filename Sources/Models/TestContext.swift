import Foundation

public final class TestContext: Codable {
    public let environment: [String: String]
    public let testDestination: TestDestination
    
    public init(environment: [String: String], testDestination: TestDestination) {
        self.environment = environment
        self.testDestination = testDestination
    }
}
