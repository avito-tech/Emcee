import Foundation
import Models
import RunnerModels

public protocol TestRunnerProvider {
    func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner
}
