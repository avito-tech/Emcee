import Foundation
import Models

public final class TestsWorkingDirectoryDeterminer {
    private let testContext: TestContext

    public init(testContext: TestContext) {
        self.testContext = testContext
    }
    
    public func testsWorkingDirectory() throws -> String {
        if let value = testContext.environment[TestsWorkingDirectorySupport.envTestsWorkingDirectory] {
            return value
        }
        throw MissingTestsWorkingDirectoryError.missingEnvironment(
            envName: TestsWorkingDirectorySupport.envTestsWorkingDirectory
        )
    }
}

