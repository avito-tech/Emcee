import Foundation
import PathLib
import RunnerModels

public final class TestsWorkingDirectoryDeterminer {
    private let testContext: TestContext

    public init(testContext: TestContext) {
        self.testContext = testContext
    }
    
    public func testsWorkingDirectory() throws -> AbsolutePath {
        if let value = testContext.environment[TestsWorkingDirectorySupport.envTestsWorkingDirectory] {
            return AbsolutePath(value)
        }
        throw MissingTestsWorkingDirectoryError.missingEnvironment(
            envName: TestsWorkingDirectorySupport.envTestsWorkingDirectory
        )
    }
}

