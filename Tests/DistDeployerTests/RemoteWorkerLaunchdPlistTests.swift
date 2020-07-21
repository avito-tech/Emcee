import Deployer
import DeployerTestHelpers
import DistDeployer
import Foundation
import PathLib
import SocketModels
import XCTest

final class RemoteWorkerLaunchdPlistTests: XCTestCase {
    let launchdPlist = RemoteWorkerLaunchdPlist(
        deploymentDestination: DeploymentDestinationFixtures().build(),
        emceeVersion: "emceeVersion",
        executableDeployableItem: DeployableItem(
            name: "emcee",
            files: [DeployableFile(source: AbsolutePath("local_file"), destination: RelativePath("remote_filename"))]
        ),
        queueAddress: SocketAddress(host: "queue.host", port: 24)
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
                "/Users/username/path/emceeVersion/emcee/remote_filename",
                "distWork",
                "--emcee-version",
                "emceeVersion",
                "--queue-server",
                "queue.host:24",
                "--worker-id",
                "localhost"
            ]
        )
        XCTAssertEqual(
            decodedDict["WorkingDirectory"] as? String,
            "/Users/username/path/emceeVersion/emcee"
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
            "ru.avito.emcee.worker.emceeVersion"
        )
    }
}

