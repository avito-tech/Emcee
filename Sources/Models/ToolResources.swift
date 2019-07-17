import Foundation

public final class ToolResources: Codable, Hashable, CustomStringConvertible {
    /// A tool to control simulators.
    public let simulatorControlTool: SimulatorControlTool
    
    /// Location of fbxctest tool.
    public let fbxctest: FbxctestLocation
    
    public init(simulatorControlTool: SimulatorControlTool, fbxctest: FbxctestLocation) {
        self.simulatorControlTool = simulatorControlTool
        self.fbxctest = fbxctest
    }
    
    public static func == (left: ToolResources, right: ToolResources) -> Bool {
        return left.simulatorControlTool == right.simulatorControlTool
            && left.fbxctest == right.fbxctest
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(simulatorControlTool)
        hasher.combine(fbxctest)
    }
    
    public var description: String {
        return "<\((type(of: self))), \(simulatorControlTool), \(fbxctest)>"
    }
    
    // MARK: - TODO: remove custom Encodable & Decodable, left for backwards compatibility
    
    private enum CodingKeys: String, CodingKey {
        case simulatorControlTool
        case fbsimctl
        case fbxctest
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(simulatorControlTool, forKey: .simulatorControlTool)
        switch simulatorControlTool {
        case .fbsimctl(let fbsimctlLocation):
            try container.encode(fbsimctlLocation, forKey: .fbsimctl)
        }
        try container.encode(fbxctest, forKey: .fbxctest)
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let fbxctest = try container.decode(FbxctestLocation.self, forKey: .fbxctest)
        
        if let simulatorControlTool = try container.decodeIfPresent(SimulatorControlTool.self, forKey: .simulatorControlTool) {
            self.init(simulatorControlTool: simulatorControlTool, fbxctest: fbxctest)
        } else {
            self.init(
                simulatorControlTool: SimulatorControlTool.fbsimctl(
                    try container.decode(FbsimctlLocation.self, forKey: .fbsimctl)
                ),
                fbxctest: fbxctest
            )
        }
    }
}
