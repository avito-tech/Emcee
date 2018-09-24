import Foundation
import Models
import XCTest
@testable import Deployer

class DeployerTests: XCTestCase {
    
    func testDeployer() throws {
        let deployableWithSingleFile = DeployableItem(
            name: "simple_file",
            files: [
                DeployableFile(source: String(#file), destination: "remote/file.swift")
            ])
        
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
        XCTAssertEqual(deployer.urlsAskedToBeDeployed.count, 1)
        
        deployer.urlsAskedToBeDeployed.forEach { url, deployable in
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            XCTAssertEqual(deployable.name, "simple_file")
            XCTAssertEqual(
                deployable.files,
                Set([DeployableFile(source: String(#file), destination: "remote/file.swift")]))
        }
    }
    
    func testDeployerDeletesItsTempFolder() throws {
        let deployableWithSingleFile = DeployableItem(
            name: "simple_file",
            files: [DeployableFile(source: String(#file), destination: "remote/file.swift")])
        
        var urls = [URL]()
        
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
            urls = Array(deployer.urlsAskedToBeDeployed.keys)
        }
        try deployerWork()
        
        XCTAssertEqual(urls.count, 1)
        urls.forEach { url in
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        }
    }
}
