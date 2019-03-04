import Foundation

public enum MissingTestsWorkingDirectoryError: Error, CustomStringConvertible {
    case missingEnvironment(envName: String)
    
    public var description: String {
        switch self {
        case .missingEnvironment(let envName):
            return "Cannot determine tests working directory: test context is missing env.\(envName)"
        }
    }
}
