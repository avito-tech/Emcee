import Foundation

public enum RunnerError: Error, CustomStringConvertible {
    case noAppBundleDefinedForUiOrApplicationTesting
    case noRunnerAppDefinedForUiTesting
    
    public var description: String {
        switch self {
        case .noAppBundleDefinedForUiOrApplicationTesting:
            return "Unable to run application or UI tests: No hosting app bundle has been provided"
        case .noRunnerAppDefinedForUiTesting:
            return "Unable to run UI tests: No runner app bundle has been provided"
        }
    }
}
