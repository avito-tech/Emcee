import Foundation
import Models
import XCTest
@testable import SSHDeployer
@testable import Deployer

class SSHDeployerTests: XCTestCase {
    func testForInputCorrectness() throws {
        let deploymentId = UUID().uuidString
        let deployableWithSingleFile = DeployableItem(
            name: "deployable_name",
            files: [
                DeployableFile(source: String(#file), destination: "remote/file.swift")
            ])
        let destination = DeploymentDestination(
            identifier: "id",
            host: "host",
            port: 1034,
            username: "user",
            password: "pa$$",
            remoteDeploymentPath: "/some/remote/container")
        
        let deployer = try SSHDeployer(
            sshClientType: FakeSSHClient.self,
            deploymentId: deploymentId,
            deployables: [deployableWithSingleFile],
            deployableCommands: [
                [
                    "string_arg",
                    .item(deployableWithSingleFile, relativePath: "remote/file.swift")
                ]
            ],
            destinations: [destination])
        try deployer.deploy()
        
        guard let client = FakeSSHClient.lastCreatedInstance else {
            XCTFail("Expected FakeSSHClient.lastCreatedInstance to be non nil as instance should be created")
            return
        }
        
        XCTAssertEqual(client.host, destination.host)
        XCTAssertEqual(client.port, destination.port)
        XCTAssertEqual(client.username, destination.username)
        XCTAssertEqual(client.password, destination.password)
        XCTAssertTrue(client.calledConnectAndAuthenticate)
        
        XCTAssertEqual(client.executeCommands.count, 4)
        XCTAssertEqual(
            client.executeCommands[0],
            ["rm", "-rf", "\(destination.remoteDeploymentPath)/\(deploymentId)/deployable_name"])
        XCTAssertEqual(
            client.executeCommands[1],
            ["mkdir", "-p", "\(destination.remoteDeploymentPath)/\(deploymentId)/deployable_name"])
        
        XCTAssertEqual(client.uploadCommands.count, 1)
        let uploadCommand = client.uploadCommands[0]
        // the key is not tested as it is a privately located file on local machine
        // we can only test that file exists
        var isDirectory: ObjCBool = false
        XCTAssertTrue(
            FileManager.default.fileExists(atPath: Array(uploadCommand.keys)[0].path, isDirectory: &isDirectory))
        XCTAssertFalse(isDirectory.boolValue)
        XCTAssertEqual(
            Array(uploadCommand.values),
            ["/some/remote/container/\(deploymentId)/deployable_name/_package.zip"])
        
        XCTAssertEqual(
            client.executeCommands[2],
            ["unzip", "\(destination.remoteDeploymentPath)/\(deploymentId)/deployable_name/_package.zip",
                "-d", "\(destination.remoteDeploymentPath)/\(deploymentId)/deployable_name"])
        XCTAssertEqual(
            client.executeCommands[3],
            ["string_arg", "/some/remote/container/\(deploymentId)/deployable_name/remote/file.swift"])
    }
}
