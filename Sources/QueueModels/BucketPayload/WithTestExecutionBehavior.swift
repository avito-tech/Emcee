import Foundation
import RunnerModels

public protocol WithTestExecutionBehavior {
    var testExecutionBehavior: TestExecutionBehavior { get }
}
