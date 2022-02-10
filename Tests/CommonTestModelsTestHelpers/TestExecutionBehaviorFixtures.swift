import CommonTestModels
import Foundation

public final class TestExecutionBehaviorFixtures {
    public var environment: [String: String]
    public var userInsertedLibraries: [String]
    public var numberOfRetries: UInt
    public var testRetryMode: TestRetryMode
    public var logCapturingMode: LogCapturingMode
    public var runnerWasteCleanupPolicy: RunnerWasteCleanupPolicy
    
    public init(
        environment: [String: String] = [:],
        userInsertedLibraries: [String] = [],
        numberOfRetries: UInt = 0,
        testRetryMode: TestRetryMode = .retryThroughQueue,
        logCapturingMode: LogCapturingMode = .noLogs,
        runnerWasteCleanupPolicy: RunnerWasteCleanupPolicy = .clean
    ) {
        self.environment = environment
        self.userInsertedLibraries = userInsertedLibraries
        self.numberOfRetries = numberOfRetries
        self.testRetryMode = testRetryMode
        self.logCapturingMode = logCapturingMode
        self.runnerWasteCleanupPolicy = runnerWasteCleanupPolicy
    }
    
    public func with(environment: [String: String]) -> Self {
        self.environment = environment
        return self
    }
    
    public func with(userInsertedLibraries: [String]) -> Self {
        self.userInsertedLibraries = userInsertedLibraries
        return self
    }
    
    public func with(numberOfRetries: UInt) -> Self {
        self.numberOfRetries = numberOfRetries
        return self
    }
    
    public func with(testRetryMode: TestRetryMode) -> Self {
        self.testRetryMode = testRetryMode
        return self
    }
    
    public func with(logCapturingMode: LogCapturingMode) -> Self {
        self.logCapturingMode = logCapturingMode
        return self
    }
    
    public func with(runnerWasteCleanupPolicy: RunnerWasteCleanupPolicy) -> Self {
        self.runnerWasteCleanupPolicy = runnerWasteCleanupPolicy
        return self
    }
    
    public func testExecutionBehavior() -> TestExecutionBehavior {
        return TestExecutionBehavior(
            environment: environment,
            userInsertedLibraries: userInsertedLibraries,
            numberOfRetries: numberOfRetries,
            testRetryMode: testRetryMode,
            logCapturingMode: logCapturingMode,
            runnerWasteCleanupPolicy: runnerWasteCleanupPolicy
        )
    }
}
