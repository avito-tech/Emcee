import Deployer
import Foundation
import PathLib
import Shout

public final class DefaultSSHClient: SSHClient {
    private let ssh: SSH
    private let username: String
    private let authentication: DeploymentDestinationAuthenticationType
    
    public init(host: String, port: Int32, username: String, authentication: DeploymentDestinationAuthenticationType) throws {
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
        case .keyInDefaultSshLocation(filename: let filename):
            try ssh.authenticate(username: username, privateKey: "~/.ssh/\(filename)")
        }
    }
    
    @discardableResult
    public func execute(_ command: [String]) throws -> Int32 {
        let shellCommand = command.map { $0.shellEscaped() }.joined(separator: " ")
        return try ssh.execute(shellCommand) { _ in }
    }
    
    public func upload(localPath: AbsolutePath, remotePath: AbsolutePath) throws {
        try ssh.openSftp().upload(localURL: localPath.fileUrl, remotePath: remotePath.pathString)
    }
}
