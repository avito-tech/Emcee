@testable import Deployer
import Foundation
import PathLib
import ProcessController
import ProcessControllerTestHelpers
import TestHelpers
import Tmp
import UniqueIdentifierGeneratorTestHelpers
import XCTest

class DeployerTests: XCTestCase {
    private let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: "fixed")
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var deployableFileSource = assertDoesNotThrow { try tempFolder.createFile(filename: "file") }
    lazy var deployableFile = DeployableFile(
        source: deployableFileSource,
        destination: RelativePath("remote/file.swift")
    )
    
    func testDeployer() throws {
        let deployableWithSingleFile = DeployableItem(
            name: "simple_file",
            files: [deployableFile]
        )
        
        let deployer = try FakeDeployer(
            deploymentId: "ID",
            deployables: [deployableWithSingleFile],
            deployableCommands: [],
            destination: DeploymentDestination(
                host: "localhost",
                port: 32,
                username: "user",
                authentication: .password("pass"),
                remoteDeploymentPath: "/remote/path"
            ),
            logger: .noOp,
            processControllerProvider: FakeProcessControllerProvider { subprocess -> ProcessController in
                XCTAssertEqual(
                    try subprocess.arguments.map { try $0.stringValue() },
                    ["/usr/bin/zip", self.tempFolder.pathWith(components: ["fixed", "simple_file"]).pathString, "-r", "."]
                )
                return FakeProcessController(subprocess: subprocess)
            },
            temporaryFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        try deployer.deploy()
        XCTAssertEqual(deployer.pathsAskedToBeDeployed.count, 1)
        
        deployer.pathsAskedToBeDeployed.forEach { path, deployable in
            XCTAssertEqual(deployable.name, "simple_file")
            XCTAssertEqual(
                deployable.files,
                Set([deployableFile])
            )
        }
    }
    
    func testDeployerDeletesItsTemporaryStuff() throws {
        let deployableWithSingleFile = DeployableItem(
            name: "simple_file",
            files: [deployableFile]
        )
        
        var paths = [AbsolutePath]()
        
        let deployerWork = {
            let deployer = try FakeDeployer(
                deploymentId: "ID",
                deployables: [deployableWithSingleFile],
                deployableCommands: [],
                destination: DeploymentDestination(
                    host: "localhost",
                    port: 32,
                    username: "user",
                    authentication: .password("pass"),
                    remoteDeploymentPath: "/remote/path"
                ),
                logger: .noOp,
                processControllerProvider: FakeProcessControllerProvider(),
                temporaryFolder: self.tempFolder,
                uniqueIdentifierGenerator: self.uniqueIdentifierGenerator
            )
            try deployer.deploy()
            paths = Array(deployer.pathsAskedToBeDeployed.keys)
        }
        try deployerWork()
        
        XCTAssertEqual(paths.count, 1)
        paths.forEach { path in
            XCTAssertFalse(FileManager.default.fileExists(atPath: path.pathString))
        }
    }
}
