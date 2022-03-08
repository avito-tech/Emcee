import Deployer
import Foundation
import PathLib

public final class DeploymentDestinationFixtures {
    
    public var host: String = "localhost"
    public var port: Int32 = 42
    public var username: String = "user"
    public var authentication: DeploymentDestinationAuthenticationType = .password("pass")
    public var remoteDeploymentPath = AbsolutePath("/Users/username/path")
    
    public init() {}
    
    public func with(host: String) -> DeploymentDestinationFixtures {
        self.host = host
        return self
    }
    
    public func with(port: Int32) -> DeploymentDestinationFixtures {
        self.port = port
        return self
    }
    
    public func with(username: String) -> DeploymentDestinationFixtures {
        self.username = username
        return self
    }
    
    public func with(authentication: DeploymentDestinationAuthenticationType) -> DeploymentDestinationFixtures {
        self.authentication = authentication
        return self
    }
    
    public func with(remoteDeploymentPath: AbsolutePath) -> DeploymentDestinationFixtures {
        self.remoteDeploymentPath = remoteDeploymentPath
        return self
    }
    
    public func build() -> DeploymentDestination {
        return DeploymentDestination(
            host: host,
            port: port,
            username: username,
            authentication: authentication,
            remoteDeploymentPath: remoteDeploymentPath,
            configuration: WorkerSpecificConfigurationDefaultValues.defaultWorkerConfiguration
        )
    }
}
