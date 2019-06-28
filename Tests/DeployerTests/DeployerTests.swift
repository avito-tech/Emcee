@testable import Deployer
import Foundation
import Models
import PathLib
import XCTest

class DeployerTests: XCTestCase {
    
    let deployableFile = DeployableFile(
        source: AbsolutePath(#file),
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
            destinations: [
                DeploymentDestination(
                    identifier: "id",
                    host: "localhost",
                    port: 32,
                    username: "user",
                    password: "pass",
                    remoteDeploymentPath: "/remote/path")
            ])
        try deployer.deploy()
        XCTAssertEqual(deployer.pathsAskedToBeDeployed.count, 1)
        
        deployer.pathsAskedToBeDeployed.forEach { path, deployable in
            XCTAssertTrue(FileManager.default.fileExists(atPath: path.pathString))
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
                destinations: [
                    DeploymentDestination(
                        identifier: "id",
                        host: "localhost",
                        port: 32,
                        username: "user",
                        password: "pass",
                        remoteDeploymentPath: "/remote/path")
                ],
                cleanUpAutomatically: true)
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
