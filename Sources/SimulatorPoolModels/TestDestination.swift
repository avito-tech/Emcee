import Foundation

public struct TestDestination: Hashable, CustomStringConvertible, Codable {
    public let deviceType: String
    public let runtime: String

    public init(
        deviceType: String,
        runtime: String
    ) throws {
        self.deviceType = deviceType
        self.runtime = try TestDestination.validateRuntime(runtime)
    }
    
    public var description: String {
        return "<\(type(of: self)) device: \(deviceType), runtime: \(runtime)>"
    }

    private static func validateRuntime(_ runtime: String) throws -> String {
        struct RuntimeVersionError: Error, CustomStringConvertible {
            let version: String
            
            var description: String {
                return "Invalid runtime version '\(version)'. Expected the runtime to be in format '10.3' or '10.3.1'"
            }
        }
        
        // Apple APIs return "patchless" Simulator version. E.g. for 10.3.1 it returns iOS 10.3.
        // Thus, when we ask runtime to be 10.3.1.
        // Interestingly, when we ask for iOS Simulator 10.3, SDK returns 10.3.1 anyway.
        // Here we are removing patch from the iOS version:
        // e.g. 11.2, 10.3 - it is fine
        let versionComponents = runtime.components(separatedBy: ".")
        if versionComponents.count > 2 {
            return Array(versionComponents.dropLast()).joined(separator: ".")
        } else if versionComponents.count == 2 {
            return runtime
        } else {
            throw RuntimeVersionError(version: runtime)
        }
    }
}
