import Deployer
import Foundation

public final class LaunchctlDeployableCommands {
    private let launchdPlistDeployableItem: DeployableItem
    private let plistFilename: String

    public init(launchdPlistDeployableItem: DeployableItem, plistFilename: String) {
        self.launchdPlistDeployableItem = launchdPlistDeployableItem
        self.plistFilename = plistFilename
    }
    
    public func forceLoadInBackgroundCommand() -> DeployableCommand {
        let args: [DeployableCommandArg] = [
            "launchctl", "load",
            "-w", "-S", "Background",
            .item(launchdPlistDeployableItem, relativePath: plistFilename)
        ]
        return DeployableCommand(args)
    }
    
    public func forceUnloadFromBackgroundCommand() -> DeployableCommand {
        let args: [DeployableCommandArg] = [
            "launchctl", "unload",
            "-w", "-S", "Background",
            .item(launchdPlistDeployableItem, relativePath: plistFilename)
        ]
        return DeployableCommand(args)
    }
}
