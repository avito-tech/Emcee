import CommonTestModels
import Foundation
import TestArgFile

public enum TransformationError: Error, CustomStringConvertible {
    case someTestsAreMissingInRuntime([TestToRun])
    case noMatchFor(TestName)
    
    public var description: String {
        switch self {
        case .someTestsAreMissingInRuntime(let testsToRun):
            return "Some tests are missing: \(testsToRun)"
        case .noMatchFor(let testName):
            return "Unable to find test match for \(testName)"
        }
    }
}
