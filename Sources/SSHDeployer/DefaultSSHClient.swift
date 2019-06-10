import Foundation
import Shout
import Basic
import CSSH

public final class DefaultSSHClient: SSHClient {
    private let ssh: SSH
    private let host: String
    private let port: Int32
    private let username: String
    private let password: String
    
    public init(host: String, port: Int32, username: String, password: String) throws {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.ssh = try SSH(host: host, port: port)
    }

    public func connectAndAuthenticate() throws {
        try ssh.authenticate(username: username, password: password)
    }
    
    @discardableResult
    public func execute(_ command: [String]) throws -> Int32 {
        let shellCommand = command.map { $0.spm_shellEscaped() }.joined(separator: " ")
        return try ssh.execute(shellCommand) { _ in }
    }
    
    public func upload(localUrl: URL, remotePath: String) throws {
        try ssh.openSftp().upload(localURL: localUrl, remotePath: remotePath)
    }
}
