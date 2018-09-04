import Foundation

public struct TestDestination: Hashable, CustomStringConvertible, Codable {
    /** Device type */
    public let deviceType: String
    
    /** Runtime version */
    public let iOSVersion: String
    
    /** Defines how many resources is required for each test. */
    public let resourceRequirement: Int
    
    public static let defaultResourceRequirement = 1

    public init(
        deviceType: String,
        iOSVersion: String,
        resourceRequirement: Int = TestDestination.defaultResourceRequirement) throws
    {
        self.deviceType = deviceType
        self.iOSVersion = try TestDestination.validateIosVersion(iOSVersion)
        guard resourceRequirement >= 1 else { throw ResourceRequirementError.invalidRequirement(resourceRequirement) }
        self.resourceRequirement = resourceRequirement
    }
    
    enum CodingKeys: CodingKey {
        case deviceType
        case iOSVersion
        case resourceRequirement
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let deviceType = try container.decode(String.self, forKey: .deviceType)
        let iOSVersion = try container.decode(String.self, forKey: .iOSVersion)
        let resourceRequirement = try container.decodeIfPresent(Int.self, forKey: .resourceRequirement)
        
        try self.init(
            deviceType: deviceType,
            iOSVersion: iOSVersion,
            resourceRequirement: resourceRequirement ?? TestDestination.defaultResourceRequirement)
    }
    
    public var description: String {
        return "<\(type(of: self)) '\(deviceType),\(iOSVersion),resource requirement: \(resourceRequirement)'>"
    }
    
    public var destinationString: String {
        return "name=\(deviceType),OS=iOS \(iOSVersion)"
    }
    
    private enum ResourceRequirementError: Error, CustomStringConvertible {
        case invalidRequirement(Int)
        var description: String {
            switch self {
            case .invalidRequirement(let amount):
                return "Invalid resource requirement: '\(amount)'. Minimum allowed value is '1'."
            }
        }
    }
    
    private static func validateIosVersion(_ iOSVersion: String) throws -> String {
        // Apple APIs return "patchless" Simulator version. E.g. for 10.3.1 it returns iOS 10.3.
        // Thus, when we ask runtime to be 10.3.1, fbxctest can't locate 10.3.1 runtime inside predicate.
        // Interestingly, when we ask for iOS Simulator 10.3, SDK returns 10.3.1 anyway.
        // Here we are removing patch from the iOS version:
        // e.g. 11.2, 10.3 - it is fine
        let versionComponents = iOSVersion.components(separatedBy: ".")
        if versionComponents.count > 2 {
            return Array(versionComponents.dropLast()).joined(separator: ".")
        } else if versionComponents.count == 2 {
            return iOSVersion
        } else {
            throw VersionError.invalidIosVersion(iOSVersion)
        }
    }
}
