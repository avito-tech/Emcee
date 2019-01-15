import DistDeployer
import Deployer
import Foundation
import XCTest

final class LaunchctlDeployableCommandsTests: XCTestCase {
    let deployableItem = DeployableItem(name: "name", files: [])
    let plistFilename = "file.plist"
    lazy var command = LaunchctlDeployableCommands(
        launchdPlistDeployableItem: deployableItem,
        plistFilename: plistFilename
    )
    
    func test___force_load_command() {
        let forceLoadCommand = command.forceLoadInBackgroundCommand()
        let expectedCommandArgs: [DeployableCommandArg] = [
            "launchctl", "load", "-w", "-S", "Background",
            .item(deployableItem, relativePath: plistFilename)
        ]
        XCTAssertEqual(
            forceLoadCommand.commandArgs,
            expectedCommandArgs
        )
    }
    
    func test___force_unload_command() {
        let forceLoadCommand = command.forceUnloadFromBackgroundCommand()
        let expectedCommandArgs: [DeployableCommandArg] = [
            "launchctl", "unload", "-w", "-S", "Background",
            .item(deployableItem, relativePath: plistFilename)
        ]
        XCTAssertEqual(
            forceLoadCommand.commandArgs,
            expectedCommandArgs
        )
    }
}

