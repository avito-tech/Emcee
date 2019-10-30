import Foundation

public final class TestContext: Codable, Hashable {
    public let developerDir: DeveloperDir
    public let environment: [String: String]
    public let testDestination: TestDestination
    
    public init(
        developerDir: DeveloperDir,
        environment: [String: String],
        testDestination: TestDestination
    ) {
        self.developerDir = developerDir
        self.environment = environment
        self.testDestination = testDestination
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(developerDir)
        hasher.combine(environment)
        hasher.combine(testDestination)
    }
    
    public static func == (left: TestContext, right: TestContext) -> Bool {
        return left.developerDir == right.developerDir
            && left.environment == right.environment
            && left.testDestination == right.testDestination
    }
}
