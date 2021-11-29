import Foundation
import RunnerModels

public protocol TestRunnerProvider {
    func testRunner() throws -> TestRunner
}
