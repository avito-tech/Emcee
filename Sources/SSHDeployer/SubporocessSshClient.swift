import Deployer
import Foundation
import PathLib
import ProcessController

public final class SubprocessSshClient: SSHClient {
    private let host: String
    private let port: Int32
    private let username: String
    private let authentication: DeploymentDestinationAuthenticationType
    private let processControllerProvider: ProcessControllerProvider
    
    static let sshPasswordEnvName = "EMCEE_SSH_PASSWORD"
    
    public init(
        processControllerProvider: ProcessControllerProvider,
        host: String,
        port: Int32,
        username: String,
        authentication: DeploymentDestinationAuthenticationType
    ) {
        self.host = host
        self.port = port
        self.username = username
        self.authentication = authentication
        self.processControllerProvider = processControllerProvider
    }

    private func sshOptions() -> [String] {
        var options = [String]()
        
        switch authentication {
        case .password:
            options = [
                "-o", "PreferredAuthentications=password",
                "-o", "PubkeyAuthentication=no",
                "-o", "StrictHostKeyChecking=no",
                "-o", "PasswordAuthentication=yes",
                "-o", "NumberOfPasswordPrompts=1",
                "-o", "Port=\(port)",
            ]
        case .key(let path):
            options = [
                "-o", "PreferredAuthentications=publickey",
                "-o", "PubkeyAuthentication=yes",
                "-o", "StrictHostKeyChecking=no",
                "-o", "IdentitiesOnly=yes",
                "-o", "IdentityFile=\(path)",
                "-o", "Port=\(port)",
            ]
        case .keyInDefaultSshLocation(let filename):
            options = [
                "-o", "PreferredAuthentications=publickey",
                "-o", "PubkeyAuthentication=yes",
                "-o", "StrictHostKeyChecking=no",
                "-o", "IdentitiesOnly=yes",
                "-o", "IdentityFile=~/.ssh/\(filename)",
                "-o", "Port=\(port)",
            ]
        }
        
        return options
    }
    
    private func expect(
        joinedCommand: String,
        sshPassword: String
    ) throws -> Subprocess {
        return Subprocess(
            arguments: [
                "/usr/bin/expect", "-c",
                """
                spawn \(joinedCommand)
                
                expect "assword:"
                send "$env(\(Self.sshPasswordEnvName))\r"
                interact
                
                set waitval [wait -i $spawn_id]
                exit [lindex $waitval 3]
                """
            ],
            environment: [
                Self.sshPasswordEnvName: sshPassword,
            ]
        )
    }
    
    @discardableResult
    public func execute(_ command: [String]) throws -> Int32 {
        let subprocess: Subprocess
        
        let sshOptions = sshOptions()
        let joinedEscapedCommand = command.map { $0.shellEscaped() }.joined(separator: " ")
        
        switch authentication {
        case .password(let password):
            let joinedSshOptions = sshOptions.map { $0.shellEscaped() }.joined(separator: " ")
            subprocess = try expect(
                joinedCommand: "/usr/bin/ssh \(joinedSshOptions) \(username.shellEscaped())@\(host.shellEscaped()) \(joinedEscapedCommand)",
                sshPassword: password
            )
        case .key, .keyInDefaultSshLocation:
            subprocess = Subprocess(
                arguments: ["/usr/bin/ssh"] + sshOptions + ["\(username)@\(host)", joinedEscapedCommand]
            )
        }
        
        let processController = try processControllerProvider.createProcessController(subprocess: subprocess)
        try processController.startAndListenUntilProcessDies()
        
        switch processController.processStatus() {
        case .terminated(let exitCode):
            return exitCode
        case .notStarted, .stillRunning:
            return 0 // never happens
        }
    }
    
    public func upload(localPath: AbsolutePath, remotePath: AbsolutePath) throws {
        let subprocess: Subprocess
        
        let sshOptions = sshOptions()
        let escapedRemotePath = scpFriendlyRemotePath(remotePath)
        
        switch authentication {
        case .password(let password):
            let joinedSshOptions = sshOptions.map { $0.shellEscaped() }.joined(separator: " ")
            subprocess = try expect(
                joinedCommand: "/usr/bin/scp \(joinedSshOptions) \(localPath.pathString.shellEscaped()) \(username.shellEscaped())@\(host.shellEscaped()):\(escapedRemotePath)",
                sshPassword: password
            )
        case .key, .keyInDefaultSshLocation:
            subprocess = Subprocess(
                arguments: ["/usr/bin/scp"] + sshOptions + [localPath.pathString, "\(username)@\(host):\(escapedRemotePath)"]
            )
        }
        
        let processController = try processControllerProvider.createProcessController(subprocess: subprocess)
        try processController.startAndWaitForSuccessfulTermination()
    }
    
    private func scpFriendlyRemotePath(_ path: AbsolutePath) -> String {
        let escapedSpaces = path.pathString.replacingOccurrences(of: " ", with: "\\ ")
        return "'\(escapedSpaces)'"
    }
}
