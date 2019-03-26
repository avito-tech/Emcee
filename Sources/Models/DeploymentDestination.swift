import Foundation

public final class DeploymentDestination: Decodable, CustomStringConvertible, Hashable {
    /**
     * Identifier can be used to apply additional configuration for this destination, see DestinationConfiguration
     * If identifier is not specified explicitly, the host name will be used as an identifier.
     */
    public let identifier: String
    public let host: String
    public let port: Int32
    public let username: String
    public let password: String
    public let remoteDeploymentPath: String
    
    enum CodingKeys: String, CodingKey {
        case identifier
        case host
        case port
        case username
        case password
        case remoteDeploymentPath
    }
    
    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let identifier = try container.decodeIfPresent(String.self, forKey: .identifier)
        let host = try container.decode(String.self, forKey: .host)
        let port = try container.decode(Int32.self, forKey: .port)
        let username = try container.decode(String.self, forKey: .username)
        let password = try container.decode(String.self, forKey: .password)
        let remoteDeploymentPath = try container.decode(String.self, forKey: .remoteDeploymentPath)
        
        self.init(
            identifier: identifier,
            host: host,
            port: port,
            username: username,
            password: password,
            remoteDeploymentPath: remoteDeploymentPath)
    }

    public init(
        identifier: String?,
        host: String,
        port: Int32,
        username: String,
        password: String,
        remoteDeploymentPath: String)
    {
        if let identifier = identifier {
            self.identifier = identifier
        } else {
            self.identifier = host
        }
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.remoteDeploymentPath = remoteDeploymentPath
    }
    
    public var description: String {
        return "<\(type(of: self)) host: \(host)>"
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
    
    public static func == (left: DeploymentDestination, right: DeploymentDestination) -> Bool {
        return left.identifier == right.identifier
    }
}
