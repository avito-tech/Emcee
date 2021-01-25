import Runner
import RunnerModels
import Tmp

public final class FakeTestRunnerProvider: TestRunnerProvider {
    public lazy var predefinedFakeTestRunner = FakeTestRunner(
        tempFolder: tempFolder
    )
    public lazy var predefinedTestRunner: TestRunner = predefinedFakeTestRunner
    private let tempFolder: TemporaryFolder

    public init(tempFolder: TemporaryFolder) {
        self.tempFolder = tempFolder
    }

    public func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner {
        return predefinedTestRunner
    }
}

