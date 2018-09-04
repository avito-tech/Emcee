import Foundation

public enum TestToRunDecodingError: Error, CustomStringConvertible {
    case decoding(String)
    
    public var description: String {
        switch self {
        case .decoding(let testName):
            return "Given test name \(testName) is invalid. Expected to have a string with format: TestClass/testMethod."
        }
    }
}
