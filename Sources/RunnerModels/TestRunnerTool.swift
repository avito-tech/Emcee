import Foundation

public enum TestRunnerTool: Codable, CustomStringConvertible, Hashable {
    /// Use `xcrun xcodebuild`
    case xcodebuild
    
    private enum ToolType: String, Codable {
        case xcodebuild
    }
    
    private enum CodingKeys: String, CodingKey {
        case toolType
    }
    
    public var description: String {
        switch self {
        case .xcodebuild:
            return "xcrun xcodebuild"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let toolType = try container.decode(ToolType.self, forKey: .toolType)
        
        switch toolType {
        case .xcodebuild:
            self = .xcodebuild
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .xcodebuild:
            try container.encode(ToolType.xcodebuild, forKey: .toolType)
        }
    }
}
