import AndroidTestModels
import AppleTestModels
import Foundation

public enum TestConfigurationContainer: Codable, Hashable, CustomStringConvertible {
    case appleTest(AppleTestConfiguration)
    case androidTest(AndroidTestConfiguration)
    
    public var description: String {
        switch self {
        case .appleTest(let appleTestConfiguration):
            return String(describing: appleTestConfiguration)
        case .androidTest(let androidTestConfiguration):
            return String(describing: androidTestConfiguration)
        }
    }
}
