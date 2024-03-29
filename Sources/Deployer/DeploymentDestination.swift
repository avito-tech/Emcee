import Foundation
import PathLib
import QueueModels

public struct DeploymentDestination: Codable, CustomStringConvertible, Hashable {
    public let workerId: WorkerId
    public let host: String
    public let port: Int32
    public let username: String
    public let authentication: DeploymentDestinationAuthenticationType
    public let remoteDeploymentPath: AbsolutePath
    public let configuration: WorkerSpecificConfiguration?
    
    enum CodingKeys: String, CodingKey {
        case host
        case port
        case username
        case authentication
        case remoteDeploymentPath
        case configuration
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let host = try container.decode(String.self, forKey: .host)
        let port = try container.decode(Int32.self, forKey: .port)
        let username = try container.decode(String.self, forKey: .username)
        let authentication = try container.decode(DeploymentDestinationAuthenticationType.self, forKey: .authentication)
        let remoteDeploymentPath = try container.decode(AbsolutePath.self, forKey: .remoteDeploymentPath)
        let configuration = try container.decodeIfPresent(WorkerSpecificConfiguration.self, forKey: .configuration)
        
        self.init(
            host: host,
            port: port,
            username: username,
            authentication: authentication,
            remoteDeploymentPath: remoteDeploymentPath,
            configuration: configuration
        )
    }

    public init(
        host: String,
        port: Int32,
        username: String,
        authentication: DeploymentDestinationAuthenticationType,
        remoteDeploymentPath: AbsolutePath,
        configuration: WorkerSpecificConfiguration?
    ) {
        self.workerId = WorkerId(value: host)
        self.host = host
        self.port = port
        self.username = username
        self.authentication = authentication
        self.remoteDeploymentPath = remoteDeploymentPath
        self.configuration = configuration
    }
    
    public var description: String {
        return "<\(type(of: self)) host: \(host)>"
    }
}
