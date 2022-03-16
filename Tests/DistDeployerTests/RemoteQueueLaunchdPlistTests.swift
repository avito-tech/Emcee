import Deployer
import DeployerTestHelpers
import DistDeployer
import Foundation
import PathLib
import QueueModels
import XCTest

final class RemoteQueueLaunchdPlistTests: XCTestCase {
    let queueServerConfigurationPath: AbsolutePath = "/path/to/queueServerConfiguration.json"
    let containerPath: AbsolutePath = "/path/to/container"
    let remoteQueueServerBinaryPath: AbsolutePath = "/path/to/remoteQueueServerBinary"
    let emceeVersion: Version = "emceeVersion"
    lazy var launchdPlist = RemoteQueueLaunchdPlist(
        deploymentId: "deploymentId",
        emceeVersion: emceeVersion,
        hostname: "hostname",
        queueServerConfigurationPath: self.queueServerConfigurationPath,
        containerPath: self.containerPath,
        remoteQueueServerBinaryPath: self.remoteQueueServerBinaryPath
    )
    
    func test() throws {
        let data = try launchdPlist.plistData()
        let decodedPlist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let decodedDict = decodedPlist as? NSDictionary else {
            XCTFail("Unexpected decode result")
            return
        }
        XCTAssertEqual(
            decodedDict["ProgramArguments"] as? Array,
            [
                "/path/to/remoteQueueServerBinary",
                "startLocalQueueServer",
                "--emcee-version", emceeVersion.value,
                "--queue-server-configuration-location", "/path/to/queueServerConfiguration.json",
                "--hostname", "hostname",
            ]
        )
        XCTAssertEqual(
            decodedDict["WorkingDirectory"] as? String,
            "/path/to/container"
        )
        XCTAssertEqual(
            decodedDict["Disabled"] as? Bool,
            true
        )
        XCTAssertEqual(
            decodedDict["LimitLoadToSessionType"] as? String,
            "Background"
        )
        XCTAssertEqual(
            decodedDict["RunAtLoad"] as? Bool,
            true
        )
        XCTAssertEqual(
            decodedDict["Label"] as? String,
            "ru.avito.emcee.queueServer.deploymentId"
        )
    }
}

