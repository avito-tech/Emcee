import Foundation

public final class SimRuntime: Hashable, Codable, CustomStringConvertible {
    /// E.g. `com.apple.CoreSimulator.SimRuntime.tvOS-15-0`
    public let fullyQualifiedId: String
    
    /// - Parameters:
    ///   - fullyQualifiedId: Fully qualified simruntime id, e.g. `com.apple.CoreSimulator.SimRuntime.tvOS-15-0`
    public init(fullyQualifiedId: String) {
        self.fullyQualifiedId = fullyQualifiedId
    }
    
    public var shortForMetrics: String {
        guard let value = fullyQualifiedId.split(separator: ".").last else {
            return "unknown_runtime"
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
    
    public static func == (lhs: SimRuntime, rhs: SimRuntime) -> Bool {
        lhs.fullyQualifiedId == rhs.fullyQualifiedId
    }
}
