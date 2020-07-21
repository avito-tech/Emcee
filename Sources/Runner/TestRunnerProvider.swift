import Foundation
import RunnerModels

public protocol TestRunnerProvider {
    func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner
}
