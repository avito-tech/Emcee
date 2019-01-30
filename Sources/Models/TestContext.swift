import Foundation

public final class TestContext: Codable, Hashable {
    public let environment: [String: String]
    public let testDestination: TestDestination
    
    public init(environment: [String: String], testDestination: TestDestination) {
        self.environment = environment
        self.testDestination = testDestination
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(environment)
        hasher.combine(testDestination)
    }
    
    public static func == (left: TestContext, right: TestContext) -> Bool {
        return left.environment == right.environment
            && left.testDestination == right.testDestination
    }
}
