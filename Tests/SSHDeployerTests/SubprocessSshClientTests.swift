@testable import SSHDeployer
import Deployer
import Foundation
import PathLib
import ProcessController
import ProcessControllerTestHelpers
import TestHelpers
import XCTest

final class SubprocessSshClientTests: XCTestCase {
    private var host = "host"
    private var port: Int32 = 42
    private var username = "username"
    private var authentication = DeploymentDestinationAuthenticationType.keyInDefaultSshLocation(filename: "")
    private lazy var processControllerProvider = FakeProcessControllerProvider()
    private lazy var client = SubprocessSshClient(
        processControllerProvider: processControllerProvider,
        host: host,
        port: port,
        username: username,
        authentication: authentication
    )
    
    private var createdProcessControllers = [FakeProcessController]()
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    
        processControllerProvider.creator = { [weak self] subprocess in
            let controller = FakeProcessController(subprocess: subprocess, processStatus: .terminated(exitCode: 0))
            self?.createdProcessControllers.append(controller)
            return controller
        }
    }
    
    // MARK: - Key at Absolute Path Auth Tests
    
    func test___execute___key_auth() throws {
        authentication = .key(path: "/path/to/id_emcee_rsa")
        
        try client.execute([
            "ls", "-l", "/some/path/to/folder with spaces"
        ])
        
        guard createdProcessControllers.count == 1, let processController = createdProcessControllers.last else {
            failTest("Unexpected count of created subprocesses")
        }
        
        assert {
            try processController.subprocess.arguments.map { try $0.stringValue() }
        } equals: {[
            "/usr/bin/ssh",
            "-o", "PreferredAuthentications=publickey",
            "-o", "PubkeyAuthentication=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "IdentitiesOnly=yes",
            "-o", "IdentityFile=/path/to/id_emcee_rsa",
            "-o", "Port=42",
            "username@host", "ls -l \'/some/path/to/folder with spaces\'"
        ]}
    }
    
    func test___upload___key_auth() throws {
        authentication = .key(path: "/path/to/id_emcee_rsa")
        
        try client.upload(
            localPath: "/local/file name",
            remotePath: "/remote/file name"
        )
        
        guard createdProcessControllers.count == 1, let processController = createdProcessControllers.last else {
            failTest("Unexpected count of created subprocesses")
        }
        
        assert {
            try processController.subprocess.arguments.map { try $0.stringValue() }
        } equals: {[
            "/usr/bin/scp",
            "-o", "PreferredAuthentications=publickey",
            "-o", "PubkeyAuthentication=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "IdentitiesOnly=yes",
            "-o", "IdentityFile=/path/to/id_emcee_rsa",
            "-o", "Port=42",
            "/local/file name",
            "username@host:'/remote/file\\ name\'",
        ]}
    }
    
    // MARK: - Default Key Location Tests
    
    func test___execute___default_key_auth() throws {
        authentication = .keyInDefaultSshLocation(filename: "id_emcee_rsa")
        
        try client.execute([
            "ls", "-l", "/some/path/to/folder with spaces"
        ])
        
        guard createdProcessControllers.count == 1, let processController = createdProcessControllers.last else {
            failTest("Unexpected count of created subprocesses")
        }
        
        assert {
            try processController.subprocess.arguments.map { try $0.stringValue() }
        } equals: {[
            "/usr/bin/ssh",
            "-o", "PreferredAuthentications=publickey",
            "-o", "PubkeyAuthentication=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "IdentitiesOnly=yes",
            "-o", "IdentityFile=~/.ssh/id_emcee_rsa",
            "-o", "Port=42",
            "username@host", "ls -l \'/some/path/to/folder with spaces\'"
        ]}
    }
    
    
    func test___upload___default_key_auth() throws {
        authentication = .keyInDefaultSshLocation(filename: "id_emcee_rsa")
        
        try client.upload(
            localPath: "/local/file name",
            remotePath: "/remote/file name"
        )
        
        guard createdProcessControllers.count == 1, let processController = createdProcessControllers.last else {
            failTest("Unexpected count of created subprocesses")
        }
        
        assert {
            try processController.subprocess.arguments.map { try $0.stringValue() }
        } equals: {[
            "/usr/bin/scp",
            "-o", "PreferredAuthentications=publickey",
            "-o", "PubkeyAuthentication=yes",
            "-o", "StrictHostKeyChecking=no",
            "-o", "IdentitiesOnly=yes",
            "-o", "IdentityFile=~/.ssh/id_emcee_rsa",
            "-o", "Port=42",
            "/local/file name",
            "username@host:'/remote/file\\ name'",
        ]}
    }
    
    // MARK: - Password Auth Tests
    
    func test___execute___password_auth() throws {
        authentication = .password("password")
        
        try client.execute([
            "ls", "-l", "/some/path/to/folder with spaces"
        ])
        
        guard createdProcessControllers.count == 1, let processController = createdProcessControllers.last else {
            failTest("Unexpected count of created subprocesses")
        }
        
        assert {
            try processController.subprocess.arguments.map { try $0.stringValue() }
        } equals: {[
            "/usr/bin/expect",
            "-c",
            """
            spawn /usr/bin/ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o NumberOfPasswordPrompts=1 -o Port=42 username@host ls -l '/some/path/to/folder with spaces'

            expect "assword:"
            send "$env(EMCEE_SSH_PASSWORD)\r"
            interact

            set waitval [wait -i $spawn_id]
            exit [lindex $waitval 3]
            """
        ]}
        
        assert {
            processController.subprocess.environment.values
        } equals: {
            [
                SubprocessSshClient.sshPasswordEnvName: "password",
            ]
        }
    }
    
    func test___upload___password_auth() throws {
        authentication = .password("password")
        
        try client.upload(localPath: "/some/local path/file with spaces", remotePath: "/some/remote path/file with spaces")
        
        guard createdProcessControllers.count == 1, let processController = createdProcessControllers.last else {
            failTest("Unexpected count of created subprocesses")
        }
        
        assert {
            try processController.subprocess.arguments.map { try $0.stringValue() }
        } equals: {[
            "/usr/bin/expect",
            "-c",
            """
            spawn /usr/bin/scp -o PreferredAuthentications=password -o PubkeyAuthentication=no -o StrictHostKeyChecking=no -o PasswordAuthentication=yes -o NumberOfPasswordPrompts=1 -o Port=42 '/some/local path/file with spaces' username@host:'/some/remote\\ path/file\\ with\\ spaces'
            
            expect "assword:"
            send "$env(EMCEE_SSH_PASSWORD)\r"
            interact
            
            set waitval [wait -i $spawn_id]
            exit [lindex $waitval 3]
            """
        ]}
        
        assert {
            processController.subprocess.environment.values
        } equals: {
            [
                SubprocessSshClient.sshPasswordEnvName: "password",
            ]
        }
    }
}
