import Foundation

public enum SimulatorControlTool: Codable, CustomStringConvertible, Hashable {
    /// Use provided fbsimctl binary
    case fbsimctl(FbsimctlLocation)
    
    public var description: String {
        switch self {
        case .fbsimctl(let fbsimctlLocation):
            return "fbsimctl at: \(fbsimctlLocation)"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = .fbsimctl(FbsimctlLocation(try .from(value)))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fbsimctl(let fbsimctlLocation):
            try container.encode(fbsimctlLocation.resourceLocation.stringValue)
        }
    }
}
