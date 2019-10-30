import Foundation
import Models

public final class TestContextFixtures {
    public var developerDir: DeveloperDir
    public var environment: [String: String]
    public var testDestination: TestDestination
    
    public init(
        developerDir: DeveloperDir = DeveloperDir.current,
        environment: [String: String] = [:],
        testDestination: TestDestination = TestDestinationFixtures.testDestination
    ) {
        self.developerDir = developerDir
        self.environment = environment
        self.testDestination = testDestination
    }
    
    public var testContext: TestContext {
        return TestContext(
            developerDir: developerDir,
            environment: environment,
            testDestination: testDestination
        )
    }
}
