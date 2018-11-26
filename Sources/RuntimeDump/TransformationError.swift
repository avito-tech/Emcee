import Foundation
import Models

public enum TransformationError: Error, CustomStringConvertible {
    case someTestsAreMissingInRuntime([TestToRun])
    case noMatchFor(TestToRun)
    case unableToExctractClassAndMethodNames(testName: String)
    
    public var description: String {
        switch self {
        case .someTestsAreMissingInRuntime(let testsToRun):
            return "Error: some tests are missing in runtime: \(testsToRun)"
        case .noMatchFor(let testToRun):
            return "Unexpected error: Unable to find expected runtime test match for \(testToRun)"
        case .unableToExctractClassAndMethodNames(let testName):
            return "Error: \(testName) is a wrong test name. Unable to extract class or method."
        }
    }
}
