import Foundation

public struct TestDestination: Hashable, CustomStringConvertible, Codable {
    /// Device type
    public let deviceType: String
    
    /// Runtime version
    public let runtime: String
    
    /// Backwards compatibility
    public var iOSVersion: String {
        return runtime
    }
    
    /// Defines how many resources is required for each test
    public let resourceRequirement: Int
    
    public static let defaultResourceRequirement = 1

    public init(
        deviceType: String,
        runtime: String,
        resourceRequirement: Int = TestDestination.defaultResourceRequirement) throws
    {
        self.deviceType = deviceType
        self.runtime = try TestDestination.validateRuntime(runtime)
        guard resourceRequirement >= 1 else { throw ResourceRequirementError.invalidRequirement(resourceRequirement) }
        self.resourceRequirement = resourceRequirement
    }
    
    enum CodingKeys: CodingKey {
        case deviceType
        case runtime
        case iOSVersion
        case resourceRequirement
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let deviceType = try container.decode(String.self, forKey: .deviceType)
        let runtime = try (try container.decodeIfPresent(String.self, forKey: .runtime)) ?? (try container.decode(String.self, forKey: .iOSVersion))
        let resourceRequirement = try container.decodeIfPresent(Int.self, forKey: .resourceRequirement)
        
        try self.init(
            deviceType: deviceType,
            runtime: runtime,
            resourceRequirement: resourceRequirement ?? TestDestination.defaultResourceRequirement)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceType, forKey: .deviceType)
        try container.encode(runtime, forKey: .runtime)
        try container.encode(resourceRequirement, forKey: .resourceRequirement)
    }
    
    public var description: String {
        return "<\(type(of: self)) '\(deviceType), \(runtime), resource requirement: \(resourceRequirement)'>"
    }
    
    public var destinationString: String {
        return "name=\(deviceType),OS=iOS \(runtime)"
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
    
    private static func validateRuntime(_ runtime: String) throws -> String {
        // Apple APIs return "patchless" Simulator version. E.g. for 10.3.1 it returns iOS 10.3.
        // Thus, when we ask runtime to be 10.3.1, fbxctest can't locate 10.3.1 runtime inside predicate.
        // Interestingly, when we ask for iOS Simulator 10.3, SDK returns 10.3.1 anyway.
        // Here we are removing patch from the iOS version:
        // e.g. 11.2, 10.3 - it is fine
        let versionComponents = runtime.components(separatedBy: ".")
        if versionComponents.count > 2 {
            return Array(versionComponents.dropLast()).joined(separator: ".")
        } else if versionComponents.count == 2 {
            return runtime
        } else {
            throw RuntimeVersionError.invalidRuntime(runtime)
        }
    }
}

public extension TestDestination {
    
    public enum HumanReadableStringParsingError: Error, CustomStringConvertible {
        case wrongFormat(String)
        public var description: String {
            switch self {
            case .wrongFormat(let string):
                return "Unable to transform string '\(string)' into test destination. Expected a value in form of: 'iPhone SE, iOS 11.4'"
            }
        }
    }
    
    public static func from(humanReadableTestDestination string: String) throws -> TestDestination {
        let scanner = Scanner(string: string)
        var scannedDeviceType: NSString?
        guard scanner.scanUpTo(", iOS ", into: &scannedDeviceType),
            let deviceType = scannedDeviceType as String?, !deviceType.isEmpty else
        {
            throw HumanReadableStringParsingError.wrongFormat(string)
        }
        scanner.scanString(", iOS ", into: nil)
        
        guard let runtime = scanner.scanToEnd() else { throw HumanReadableStringParsingError.wrongFormat(string) }
        return try TestDestination(deviceType: deviceType, runtime: runtime)
    }
    
    public var humanReadableTestDestination: String {
        return "\(deviceType), iOS \(runtime)"
    }
}
