import Foundation
import ResourceLocation

public enum SimulatorControlTool: Codable, CustomStringConvertible, Hashable {
    /// Use provided fbsimctl binary
    case fbsimctl(FbsimctlLocation)

    /// Use default tool
    case simctl
    
    public var description: String {
        switch self {
        case .fbsimctl(let fbsimctlLocation):
            return "fbsimctl at: \(fbsimctlLocation)"
        case .simctl:
            return "simctl"
        }
    }

    private enum CodingKeys: String, CodingKey, Codable {
        case toolType
        case location
    }

    private enum ToolType: String, Codable {
        case fbsimctl
        case simctl
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let toolType = try container.decode(ToolType.self, forKey: .toolType)
        switch toolType {
        case .fbsimctl:
            self = .fbsimctl(
                FbsimctlLocation(
                    try container.decode(ResourceLocation.self, forKey: .location)
                )
            )
        case .simctl:
            self = .simctl
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fbsimctl(let fbsimctlLocation):
            try container.encode(ToolType.fbsimctl, forKey: .toolType)
            try container.encode(fbsimctlLocation.resourceLocation, forKey: .location)
        case .simctl:
            try container.encode(ToolType.simctl, forKey: .toolType)
        }
    }
}
