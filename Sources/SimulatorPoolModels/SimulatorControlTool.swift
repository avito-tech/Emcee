import Foundation
import ResourceLocation

public struct SimulatorControlTool: Codable, CustomStringConvertible, Hashable {
    public let location: SimulatorLocation
    public let tool: SimCtlTool
    
    public init(
        location: SimulatorLocation,
        tool: SimCtlTool
    ) {
        self.location = location
        self.tool = tool
    }
    
    public var description: String {
        return "<\(type(of: self)) tool: \(tool) location: \(location)>"
    }
}

public enum SimulatorLocation: String, Codable, CustomStringConvertible, Hashable {
    /// Allows to create a private simulators in Emcee's temporary folder. Currently only supported by `fbxctest` runner. `xcodebuild` cannot locate these simulators yet.
    case insideEmceeTempFolder
    
    /// Default location used by simctl and Xcode: `~/Library/Developer/CoreSimulator/Devices`
    case insideUserLibrary
    
    public var description: String {
        switch self {
        case .insideEmceeTempFolder:
            return "<\(type(of: self)) inside temp folder>"
        case .insideUserLibrary:
            return "<\(type(of: self)) inside default location>"
        }
    }
}

public enum SimCtlTool: Codable, CustomStringConvertible, Hashable {
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
