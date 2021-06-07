import Foundation
@testable import SSHDeployer
import Deployer

class FakeSSHClient: SSHClient {
    let host: String
    let port: Int32
    let username: String
    let authentication: DeploymentDestinationAuthenticationType
    
    var calledConnectAndAuthenticate = false
    var executeCommands = [[String]]()
    var uploadCommands = [[URL: String]]()
    
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
    
    func upload(localUrl: URL, remotePath: String) throws {
        uploadCommands.append([localUrl: remotePath])
    }
    
    static var lastCreatedInstance: FakeSSHClient? 
}
