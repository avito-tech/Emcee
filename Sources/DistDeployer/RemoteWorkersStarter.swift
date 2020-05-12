import Deployer
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import TemporaryStuff
import UniqueIdentifierGenerator

/// Starts the remote workers on the given destinations that will poll jobs from the given queue
public final class RemoteWorkersStarter {
    private let deploymentDestinations: [DeploymentDestination]
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        deploymentDestinations: [DeploymentDestination],
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.deploymentDestinations = deploymentDestinations
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func deployAndStartWorkers(
        deployQueue: DispatchQueue,
        emceeVersion: Version,
        queueAddress: SocketAddress
    ) throws {
        let deployablesGenerator = DeployablesGenerator(
            emceeVersion: emceeVersion,
            remoteEmceeBinaryName: "EmceeWorker"
        )
        try deployAndStartWorkers(
            deployQueue: deployQueue,
            deployableItems: try deployablesGenerator.deployables(),
            emceeBinaryDeployableItem: try deployablesGenerator.runnerTool(),
            emceeVersion: emceeVersion,
            queueAddress: queueAddress
        )
    }
    
    private func deployAndStartWorkers(
        deployQueue: DispatchQueue,
        deployableItems: [DeployableItem],
        emceeBinaryDeployableItem: DeployableItem,
        emceeVersion: Version,
        queueAddress: SocketAddress
    ) throws {
        for destination in deploymentDestinations {
            let launchdPlist = RemoteWorkerLaunchdPlist(
                deploymentDestination: destination,
                emceeVersion: emceeVersion,
                executableDeployableItem: emceeBinaryDeployableItem,
                queueAddress: queueAddress
            )
            let launchdPlistTargetPath = "launchd_\(destination.identifier).plist"
            
            let filePath = try tempFolder.createFile(
                filename: launchdPlistTargetPath,
                contents: try launchdPlist.plistData()
            )
            
            deployQueue.async { [processControllerProvider, tempFolder, uniqueIdentifierGenerator] in
                Logger.debug("Deploying to \(destination)")
                
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
                    deploymentDestinations: [destination],
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
                
                do {
                    try deployer.deploy(deployQueue: deployQueue)
                } catch {
                    Logger.error("Failed to deploy to \(destination): \(error). This error will be ignored.")
                }
            }
        }
    }
}
