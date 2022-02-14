import Deployer
import Foundation
import SSHDeployer

open class FakeSSHClientProvider: SSHClientProvider {
    public var resultProvider: (String, Int32, String, DeploymentDestinationAuthenticationType) throws -> FakeSSHClient
    
    public init(
        resultProvider: @escaping (String, Int32, String, DeploymentDestinationAuthenticationType) throws -> FakeSSHClient = { host, port, username, authentication in
            try FakeSSHClient(host: host, port: port, username: username, authentication: authentication)
        }
    ) {
        self.resultProvider = resultProvider
    }
    
    public var providedClients: [SSHClient] = []
    
    public func createClient(host: String, port: Int32, username: String, authentication: DeploymentDestinationAuthenticationType) throws -> SSHClient {
        let client = try resultProvider(host, port, username, authentication)
        providedClients.append(client)
        return client
    }
}
