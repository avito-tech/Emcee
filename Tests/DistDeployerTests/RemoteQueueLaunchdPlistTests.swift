import Deployer
import DistDeployer
import Foundation
import Models
import ModelsTestHelpers
import PathLib
import XCTest

final class RemoteQueueLaunchdPlistTests: XCTestCase {
    let remoteConfigUrl = URL(string: "http://example.com/file.zip#config.json")!
    lazy var launchdPlist = RemoteQueueLaunchdPlist(
        deploymentId: "deploymentId",
        deploymentDestination: DeploymentDestinationFixtures().buildDeploymentDestination(),
        emceeDeployableItem: DeployableItem(
            name: "emcee",
            files: [
                DeployableFile(
                    source: AbsolutePath("local_file"),
                    destination: RelativePath("remote_filename")
                )
            ]
        ),
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
                "--queue-server-run-configuration-location",
                remoteConfigUrl.absoluteString
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

