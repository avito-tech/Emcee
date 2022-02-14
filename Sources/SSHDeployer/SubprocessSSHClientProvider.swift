import Deployer
import Foundation
import ProcessController

public final class SubprocessSSHClientProvider: SSHClientProvider {
    private let processControllerProvider: ProcessControllerProvider
    
    public init(
        processControllerProvider: ProcessControllerProvider
    ) {
        self.processControllerProvider = processControllerProvider
    }
    
    public func createClient(
        host: String,
        port: Int32,
        username: String,
        authentication: DeploymentDestinationAuthenticationType
    ) throws -> SSHClient {
        SubprocessSshClient(
            processControllerProvider: processControllerProvider,
            host: host,
            port: port,
            username: username,
            authentication: authentication
        )
    }
}
