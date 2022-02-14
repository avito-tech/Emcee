@testable import SSHDeployer
import Foundation
import Deployer
import PathLib

open class FakeSSHClient: SSHClient {
    let host: String
    let port: Int32
    let username: String
    let authentication: DeploymentDestinationAuthenticationType
    
    var executeCommands = [[String]]()
    var uploadCommands = [(local: AbsolutePath, remote: AbsolutePath)]()
    
    public init(host: String, port: Int32, username: String, authentication: DeploymentDestinationAuthenticationType) throws {
        self.host = host
        self.port = port
        self.username = username
        self.authentication = authentication
    }
    
    @discardableResult
    public func execute(_ command: [String]) throws -> Int32 {
        executeCommands.append(command)
        return 0
    }
    
    public func upload(localPath: AbsolutePath, remotePath: AbsolutePath) throws {
        uploadCommands.append((local: localPath, remote: remotePath))
    }
}
