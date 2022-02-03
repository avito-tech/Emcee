import Foundation

public struct TestDestination: Hashable, CustomStringConvertible, Codable {
    /// Device type. Examples:
    /// - `com.apple.CoreSimulator.SimDeviceType.iPhone-X`
    /// - `com.apple.CoreSimulator.SimDeviceType.iPad-mini-6th-generation`
    /// - `com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-4K`
    public let simDeviceType: String
    
    /// Platform-specific runtime. Examples:
    /// - `com.apple.CoreSimulator.SimRuntime.iOS-15-1`
    /// - `com.apple.CoreSimulator.SimRuntime.tvOS-15-0`
    public let simRuntime: String

    public init(
        simDeviceType: String,
        simRuntime: String
    )  {
        self.simDeviceType = simDeviceType
        self.simRuntime = simRuntime
    }
    
    private enum CodingKeys: CodingKey {
        case simDeviceType
        case simRuntime
        
        case deviceType
        case runtime
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            self.init(
                simDeviceType: try container.decode(String.self, forKey: .simDeviceType),
                simRuntime: try container.decode(String.self, forKey: .simRuntime)
            )
        } catch {
            self = Self.appleSimulator(
                deviceType: try container.decode(String.self, forKey: .deviceType),
                kind: .iOS,
                version: try container.decode(String.self, forKey: .runtime)
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(simRuntime, forKey: .simRuntime)
        try container.encode(simDeviceType, forKey: .simDeviceType)
    }
    
    public var description: String {
        return "<\(simDeviceType) \(simRuntime)>"
    }
}
