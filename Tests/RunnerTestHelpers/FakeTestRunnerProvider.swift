import Runner
import RunnerModels

public final class FakeTestRunnerProvider: TestRunnerProvider {
    public lazy var predefinedFakeTestRunner = FakeTestRunner()
    public lazy var predefinedTestRunner: TestRunner = predefinedFakeTestRunner

    public init() {}

    public func testRunner() throws -> TestRunner {
        return predefinedTestRunner
    }
}

