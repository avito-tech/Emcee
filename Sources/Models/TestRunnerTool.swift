import Foundation

public enum TestRunnerTool: Codable, CustomStringConvertible, Hashable {
    /// Use provided fbxctest binary
    case fbxctest(FbxctestLocation)

    /// Use `xcrun xcodebuild`
    case xcodebuild
    
    private enum ToolType: String, Codable {
        case fbxctest
        case xcodebuild
    }
    
    private enum CodingKeys: String, CodingKey {
        case toolType
        case fbxctestLocation
    }
    
    public var description: String {
        switch self {
        case .fbxctest(let fbxctestLocation):
            return "fbxctest at: \(fbxctestLocation)"
        case .xcodebuild:
            return "xcrun xcodebuild"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let toolType = try container.decode(ToolType.self, forKey: .toolType)
        
        switch toolType {
        case .fbxctest:
            self = .fbxctest(try container.decode(FbxctestLocation.self, forKey: .fbxctestLocation))
        case .xcodebuild:
            self = .xcodebuild
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fbxctest(let location):
            try container.encode(ToolType.fbxctest, forKey: .toolType)
            try container.encode(location, forKey: .fbxctestLocation)
        case .xcodebuild:
            try container.encode(ToolType.xcodebuild, forKey: .toolType)
        }
    }
}
