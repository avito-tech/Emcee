import Foundation
@testable import SSHDeployer
import Deployer
import PathLib

class FakeSSHClient: SSHClient {
    let host: String
    let port: Int32
    let username: String
    let authentication: DeploymentDestinationAuthenticationType
    
    var calledConnectAndAuthenticate = false
    var executeCommands = [[String]]()
    var uploadCommands = [(local: AbsolutePath, remote: AbsolutePath)]()
    
    required init(host: String, port: Int32, username: String, authentication: DeploymentDestinationAuthenticationType) throws {
        self.host = host
        self.port = port
        self.username = username
        self.authentication = authentication
        
        FakeSSHClient.lastCreatedInstance = self
    }
    
    func connectAndAuthenticate() throws {
        calledConnectAndAuthenticate = true
    }
    
    @discardableResult
    func execute(_ command: [String]) throws -> Int32 {
        executeCommands.append(command)
        return 0
    }
    
    func upload(localPath: AbsolutePath, remotePath: AbsolutePath) throws {
        uploadCommands.append((local: localPath, remote: remotePath))
    }
    
    static var lastCreatedInstance: FakeSSHClient? 
}
