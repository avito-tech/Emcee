import Foundation
import Shout
import PathLib
import Deployer

public final class DefaultSSHClient: SSHClient {
    private let ssh: SSH
    private let host: String
    private let port: Int32
    private let username: String
    private let authentication: DeploymentDestinationAuthenticationType
    
    public init(host: String, port: Int32, username: String, authentication: DeploymentDestinationAuthenticationType) throws {
        self.host = host
        self.port = port
        self.username = username
        self.authentication = authentication
        self.ssh = try SSH(host: host, port: port)
    }

    public func connectAndAuthenticate() throws {
        switch authentication{
        case .password(let password):
            try ssh.authenticate(username: username, password: password)
        case .key(let path):
            try ssh.authenticate(username: username, privateKey: path.pathString)
        }
    }
    
    @discardableResult
    public func execute(_ command: [String]) throws -> Int32 {
        let shellCommand = command.map { $0.shellEscaped() }.joined(separator: " ")
        return try ssh.execute(shellCommand) { _ in }
    }
    
    public func upload(localUrl: URL, remotePath: String) throws {
        try ssh.openSftp().upload(localURL: localUrl, remotePath: remotePath)
    }
}
