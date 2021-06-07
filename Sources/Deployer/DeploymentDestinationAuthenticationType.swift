import Foundation

public enum DeploymentDestinationAuthenticationType: Codable, CustomStringConvertible, Equatable, Hashable {
    case plain(password: String)
    case key(path: String)
    
    public var description: String {
        switch self {
        case .plain:
            return "user-password auth"
        case .key:
            return "key authorization"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case period
        case password
        case path
    }
    
    private enum AuthType: String, Codable {
        case plain
        case key
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(AuthType.self, forKey: .type)

        switch type {
        case .plain:
            self = .plain(password: try container.decode(String.self, forKey: .password))
        case .key:
            self = .key(path: try container.decode(String.self, forKey: .path))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .plain(let password):
            try container.encode(AuthType.plain, forKey: .type)
            try container.encode(password, forKey: .password)
        case .key(let path):
            try container.encode(AuthType.key, forKey: .type)
            try container.encode(path, forKey: .path)
        }
    }
}
