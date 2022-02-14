import Deployer
import Foundation

public protocol SSHClientProvider {
    func createClient(
        host: String,
        port: Int32,
        username: String,
        authentication: DeploymentDestinationAuthenticationType
    ) throws -> SSHClient
}
