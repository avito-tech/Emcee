import Foundation

public protocol TestRunnerProvider {
    func testRunner() throws -> TestRunner
}
