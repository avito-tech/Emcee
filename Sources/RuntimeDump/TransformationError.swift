import Foundation
import Models

public enum TransformationError: Error, CustomStringConvertible {
    case someTestsAreMissingInRuntime([TestToRun])
    case noMatchFor(TestName)
    
    public var description: String {
        switch self {
        case .someTestsAreMissingInRuntime(let testsToRun):
            return "Error: some tests are missing in runtime: \(testsToRun)"
        case .noMatchFor(let testName):
            return "Unexpected error: Unable to find runtime test match for \(testName)"
        }
    }
}
