import Foundation

public enum TestRunnerTool: Codable, CustomStringConvertible, Hashable {
    /// Use provided fbxctest binary
    case fbxctest(FbxctestLocation)
    
    public var description: String {
        switch self {
        case .fbxctest(let fbxctestLocation):
            return "fbxctest at: \(fbxctestLocation)"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = .fbxctest(try container.decode(FbxctestLocation.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .fbxctest(let fbxctestLocation):
            try container.encode(fbxctestLocation.resourceLocation.stringValue)
        }
    }
}
