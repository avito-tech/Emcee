import Foundation
import PathLib

public enum DeploymentDestinationAuthenticationType: Codable, CustomStringConvertible, Equatable, Hashable {
    case password(String)
    
    /// Absolute (arbitrary) path to a local key file.
    case key(path: AbsolutePath)
    
    // Look up a key inside ~/.ssh/
    case keyInDefaultSshLocation(filename: String)
    
    public var description: String {
        switch self {
        case .password:
            return "password auth"
        case .key:
            return "authorization using a key file at absolute path"
        case .keyInDefaultSshLocation:
            return "authorization using key from ~/.ssh/"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case password
        case keyPath
        case filename
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            self = .password(try container.decode(String.self, forKey: .password))
        } catch {
            do {
                self = .key(path: try container.decode(AbsolutePath.self, forKey: .keyPath))
            } catch {
                self = .keyInDefaultSshLocation(filename: try container.decode(String.self, forKey: .filename))
            }
            
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .password(let password):
            try container.encode(password, forKey: .password)
        case .key(let path):
            try container.encode(path, forKey: .keyPath)
        case .keyInDefaultSshLocation(let filename):
            try container.encode(filename, forKey: .filename)
        }
    }
}
