import Foundation
import Models

public protocol TestRunnerProvider {
    func testRunner(testRunnerTool: TestRunnerTool) throws -> TestRunner
}
