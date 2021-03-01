import Deployer
import Foundation
import EmceeLogging
import PathLib
import ProcessController
import QueueModels
import SocketModels
import Tmp
import UniqueIdentifierGenerator

public final class DefaultRemoteWorkersStarter: RemoteWorkerStarter {
    private let deploymentDestination: DeploymentDestination
    private let emceeVersion: Version
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.deploymentDestination = deploymentDestination
        self.emceeVersion = emceeVersion
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func deployAndStartWorker(
        queueAddress: SocketAddress
    ) throws {
        let deployablesGenerator = DeployablesGenerator(
            emceeVersion: emceeVersion,
            remoteEmceeBinaryName: "EmceeWorker"
        )
        let deployableItems = try deployablesGenerator.deployables()
        let emceeBinaryDeployableItem = try deployablesGenerator.runnerTool()
        
        let launchdPlist = RemoteWorkerLaunchdPlist(
            deploymentDestination: deploymentDestination,
            emceeVersion: emceeVersion,
            executableDeployableItem: emceeBinaryDeployableItem,
            queueAddress: queueAddress
        )
        let launchdPlistTargetPath = "launchd_\(deploymentDestination.workerId.value).plist"
        
        let filePath = try tempFolder.createFile(
            filename: launchdPlistTargetPath,
            contents: try launchdPlist.plistData()
        )
        
        Logger.debug("Deploying to \(deploymentDestination)")
        
        let launchdDeployableItem = DeployableItem(
            name: "launchd_plist",
            files: [
                DeployableFile(
                    source: filePath,
                    destination: RelativePath(launchdPlistTargetPath)
                )
            ]
        )
        let launchctlDeployableCommands = LaunchctlDeployableCommands(
            launchdPlistDeployableItem: launchdDeployableItem,
            plistFilename: launchdPlistTargetPath
        )
        
        let deployer = DistDeployer(
            deploymentId: emceeVersion.value,
            deploymentDestination: deploymentDestination,
            deployableItems: deployableItems + [launchdDeployableItem],
            deployableCommands: [
                launchctlDeployableCommands.forceUnloadFromBackgroundCommand(),
                [
                    "sleep", "2"        // launchctl is async, so we have to wait :(
                ],
                launchctlDeployableCommands.forceLoadInBackgroundCommand()
            ],
            processControllerProvider: processControllerProvider,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        
        try deployer.deploy()
    }
}
