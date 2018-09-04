import Foundation

public enum PackageName: String {
    case avitoRunner
    case fbsimctl
    case fbxctest
    case app
    case additionalApp
    case testRunner
    case environment
    case simulatorLocalizationSettings
    case watchdogSettings
    case xctestBundle
    
    /** Predefined names for some package files that are expected to be present at the remote host. */
    private static let targetFileName: [PackageName: String] = [
        .fbxctest: "fbxctest",
        .fbsimctl: "fbsimctl",
        .environment: "environment.json",
        .simulatorLocalizationSettings: "simulator_settings.json",
        .watchdogSettings: "watchdog_settings.json"
    ]
    
    public enum TargetFileNameError: Error, CustomStringConvertible {
        case missingValueForPackageName(PackageName)
        
        public var description: String {
            switch self {
            case .missingValueForPackageName(let packageName):
                return "Missing value for package with name '\(packageName.rawValue)'"
            }
        }
    }
    
    public static func targetFileName(_ packageName: PackageName) throws -> String {
        guard let value = targetFileName[packageName] else {
            throw TargetFileNameError.missingValueForPackageName(packageName)
        }
        return value
    }
}
