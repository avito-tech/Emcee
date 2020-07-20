import Deployer
import DeployerTestHelpers
import DistDeployer
import Foundation
import Models
import ModelsTestHelpers
import PathLib
import QueueModels
import XCTest

final class RemoteQueueLaunchdPlistTests: XCTestCase {
    let remoteConfigUrl = URL(string: "http://example.com/file.zip#config.json")!
    let emceeVersion: Version = "emceeVersion"
    lazy var launchdPlist = RemoteQueueLaunchdPlist(
        deploymentId: "deploymentId",
        deploymentDestination: DeploymentDestinationFixtures().build(),
        emceeDeployableItem: DeployableItem(
            name: "emcee",
            files: [
                DeployableFile(
                    source: AbsolutePath("local_file"),
                    destination: RelativePath("remote_filename")
                )
            ]
        ),
        emceeVersion: emceeVersion,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation(.remoteUrl(remoteConfigUrl))
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
                "/Users/username/path/deploymentId/emcee/remote_filename",
                "startLocalQueueServer",
                "--emcee-version", emceeVersion.value,
                "--queue-server-run-configuration-location", remoteConfigUrl.absoluteString
            ]
        )
        XCTAssertEqual(
            decodedDict["WorkingDirectory"] as? String,
            "/Users/username/path/deploymentId/emcee"
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

