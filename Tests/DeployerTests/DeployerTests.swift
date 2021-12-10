@testable import Deployer
import Foundation
import FileSystemTestHelpers
import PathLib
import TestHelpers
import Tmp
import UniqueIdentifierGeneratorTestHelpers
import XCTest
import ZipTestHelpers

class DeployerTests: XCTestCase {
    private let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: "fixed")
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var deployableFileSource = assertDoesNotThrow { try tempFolder.createFile(filename: "file") }
    lazy var deployableFile = DeployableFile(
        source: deployableFileSource,
        destination: RelativePath("remote/file.swift")
    )
    lazy var fileSystem = FakeFileSystem(rootPath: tempFolder.absolutePath)
    lazy var zipCompressor = FakeZipCompressor()
    
    func testDeployer() throws {
        let deployableWithSingleFile = DeployableItem(
            name: "simple_file",
            files: [deployableFile]
        )
        
        let filePropertiesContainer = FakeFilePropertiesContainer()
        fileSystem.propertiesProvider = { _ in filePropertiesContainer }
        filePropertiesContainer.pathExists = false
        
        let zipCompressorInvoker = XCTestExpectation()
        zipCompressor.handler = { (archivePath: AbsolutePath,
                                    workingDirectory: AbsolutePath,
                                    contentsToCompress: RelativePath) -> AbsolutePath in
            assert {
                archivePath
            } equals: {
                self.tempFolder.pathWith(components: ["fixed", "simple_file"])
            }
            
            assert {
                workingDirectory
            } equals: {
                self.tempFolder.pathWith(components: ["fixed"])
            }
            
            assert {
                contentsToCompress
            } equals: {
                RelativePath("./")
            }
            
            zipCompressorInvoker.fulfill()
            
            return archivePath.appending(extension: "fake.zip")
        }
        
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
            fileSystem: fileSystem,
            logger: .noOp,
            temporaryFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            zipCompressor: zipCompressor
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
        
        wait(for: [zipCompressorInvoker], timeout: 3)
    }
    
    func testDeployerDeletesItsTemporaryStuff() throws {
        let deployableWithSingleFile = DeployableItem(
            name: "simple_file",
            files: [deployableFile]
        )
        
        var paths = [AbsolutePath]()
        
        let deployerWork = {
            self.zipCompressor.handler = { archive, _, _ in archive }
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
                fileSystem: self.fileSystem,
                logger: .noOp,
                temporaryFolder: self.tempFolder,
                uniqueIdentifierGenerator: self.uniqueIdentifierGenerator,
                zipCompressor: self.zipCompressor
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
