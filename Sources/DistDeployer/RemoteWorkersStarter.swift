import Deployer
import Foundation
import Logging
import Models
import PathLib
import TemporaryStuff
import Version

/// Starts the remote workers on the given destinations that will poll jobs from the given queue
public final class RemoteWorkersStarter {
    private let emceeVersionProvider: VersionProvider
    private let deploymentDestinations: [DeploymentDestination]
    private let tempFolder: TemporaryFolder

    public init(
        emceeVersionProvider: VersionProvider,
        deploymentDestinations: [DeploymentDestination],
        tempFolder: TemporaryFolder
    ) {
        self.emceeVersionProvider = emceeVersionProvider
        self.deploymentDestinations = deploymentDestinations
        self.tempFolder = tempFolder
    }
    
    public func deployAndStartWorkers(queueAddress: SocketAddress) throws {
        let deployablesGenerator = DeployablesGenerator(
            emceeVersionProvider: emceeVersionProvider,
            remoteEmceeBinaryName: "EmceeWorker"
        )
        try deployAndStartWorkers(
            deployableItems: try deployablesGenerator.deployables(),
            emceeBinaryDeployableItem: try deployablesGenerator.runnerTool(),
            queueAddress: queueAddress
        )
    }
    
    private func deployAndStartWorkers(
        deployableItems: [DeployableItem],
        emceeBinaryDeployableItem: DeployableItem,
        queueAddress: SocketAddress
    ) throws {
        let deployQueue = DispatchQueue(label: "RemoteWorkersStarter.deployQueue", attributes: .concurrent)
        
        let emceeVersion = try emceeVersionProvider.version().value
        
        for destination in deploymentDestinations {
            let launchdPlist = RemoteWorkerLaunchdPlist(
                deploymentId: emceeVersion,
                deploymentDestination: destination,
                executableDeployableItem: emceeBinaryDeployableItem,
                queueAddress: queueAddress
            )
            let launchdPlistTargetPath = "launchd_\(destination.identifier).plist"
            
            let filePath = try tempFolder.createFile(
                filename: launchdPlistTargetPath,
                contents: try launchdPlist.plistData()
            )
            
            deployQueue.async { [tempFolder] in
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
                    deploymentId: emceeVersion,
                    deploymentDestinations: [destination],
                    deployableItems: deployableItems + [launchdDeployableItem],
                    deployableCommands: [
                        launchctlDeployableCommands.forceUnloadFromBackgroundCommand(),
                        [
                            "sleep", "2"        // launchctl is async, so we have to wait :(
                        ],
                        launchctlDeployableCommands.forceLoadInBackgroundCommand()
                    ],
                    tempFolder: tempFolder
                )
                
                do {
                    try deployer.deploy()
                } catch {
                    Logger.error("Failed to deploy to \(destination): \(error). This error will be ignored.")
                }
            }
        }
        
        deployQueue.sync(flags: .barrier) {
            Logger.debug("Finished deploying workers")
        }
    }
}
