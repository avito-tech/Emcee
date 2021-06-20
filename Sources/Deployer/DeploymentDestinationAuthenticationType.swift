import Foundation
import PathLib

public enum DeploymentDestinationAuthenticationType: Codable, CustomStringConvertible, Equatable, Hashable {
    case password(String)
    case key(path: AbsolutePath)
    
    public var description: String {
        switch self {
        case .password:
            return "password auth"
        case .key:
            return "key authorization"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case password
        case keyPath
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            self = .password(try container.decode(String.self, forKey: .password))
        } catch {
            self = .key(path: try container.decode(AbsolutePath.self, forKey: .keyPath))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .password(let password):
            try container.encode(password, forKey: .password)
        case .key(let path):
            try container.encode(path, forKey: .keyPath)
        }
    }
}
