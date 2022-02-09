import Foundation

public final class SimDeviceType: Hashable, Codable, CustomStringConvertible {
    /// E.g. `com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---4th-generation-`
    public let fullyQualifiedId: String
    
    /// - Parameters:
    ///   - fullyQualifiedId: Fully qualified simDeviceType, e.g. `com.apple.CoreSimulator.SimDeviceType.iPad-Pro--12-9-inch---4th-generation-`
    public init(fullyQualifiedId: String) {
        self.fullyQualifiedId = fullyQualifiedId
    }
    
    public var shortForMetrics: String {
        guard let value = fullyQualifiedId.split(separator: ".").last else {
            return "unknown_device_type"
        }
        return value.replacingOccurrences(of: "-", with: "_")
    }
    
    public var description: String { fullyQualifiedId }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.fullyQualifiedId = try container.decode(String.self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(fullyQualifiedId)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(fullyQualifiedId)
    }
    
    public static func == (lhs: SimDeviceType, rhs: SimDeviceType) -> Bool {
        lhs.fullyQualifiedId == rhs.fullyQualifiedId
    }
}
