@testable import Deployer
@testable import SSHDeployer
import FileSystemTestHelpers
import Foundation
import PathLib
import Tmp
import TestHelpers
import UniqueIdentifierGeneratorTestHelpers
import XCTest
import ZipTestHelpers

class SSHDeployerTests: XCTestCase {
    private let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: "fixed")
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private lazy var fileSystem = FakeFileSystem(rootPath: tempFolder.absolutePath)
    private lazy var zipCompressor = FakeZipCompressor { path, _, _ in
        path.appending(extension: "fakezip")
    }
    
    func testForInputCorrectness() throws {
        let filePropertiesContainer = FakeFilePropertiesContainer()
        fileSystem.propertiesProvider = { _ in filePropertiesContainer }
        filePropertiesContainer.pathExists = false

        let deploymentId = UUID().uuidString
        let deployableWithSingleFile = DeployableItem(
            name: "deployable_name",
            files: [
                DeployableFile(source: AbsolutePath(#file), destination: RelativePath(components: ["remote", "file.swift"]))
            ])
        let destination = DeploymentDestination(
            host: "host",
            port: 1034,
            username: "user",
            authentication: .password("pa$$"),
            remoteDeploymentPath: "/some/remote/container"
        )
        
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
            destination: destination,
            fileSystem: fileSystem,
            logger: .noOp,
            temporaryFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            zipCompressor: zipCompressor
        )
        try deployer.deploy()
        
        guard let client = FakeSSHClient.lastCreatedInstance else {
            XCTFail("Expected FakeSSHClient.lastCreatedInstance to be non nil as instance should be created")
            return
        }
        
        XCTAssertEqual(client.host, destination.host)
        XCTAssertEqual(client.port, destination.port)
        XCTAssertEqual(client.username, destination.username)
        XCTAssertEqual(client.authentication, destination.authentication)
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
        
        assert {
            uploadCommand.local
        } equals: {
            tempFolder.pathWith(components: ["fixed", "deployable_name.fakezip"])
        }
        assert {
            uploadCommand.remote
        } equals: {
            AbsolutePath("/some/remote/container/\(deploymentId)/deployable_name/_package.zip")
        }
        
        assert {
            client.executeCommands[2]
        } equals: {
            [
                "unzip",
                "\(destination.remoteDeploymentPath)/\(deploymentId)/deployable_name/_package.zip",
                "-d",
                "\(destination.remoteDeploymentPath)/\(deploymentId)/deployable_name",
            ]
        }
        
        assert {
            client.executeCommands[3]
        } equals: {
            ["string_arg", "/some/remote/container/\(deploymentId)/deployable_name/remote/file.swift"]
        }
    }
}
