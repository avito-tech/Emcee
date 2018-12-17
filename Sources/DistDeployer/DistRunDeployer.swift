import Deployer
import Foundation
import LaunchdUtils
import Logging
import Models
import SSHDeployer
import TempFolder

public final class DistRunDeployer {
    
    private let deployerConfiguration: DeployerConfiguration
    private static let avitoRunnerTargetPath = "AvitoRunner"
    private let generator: DeployablesGenerator
    private let tempFolder: TempFolder

    public init(deployerConfiguration: DeployerConfiguration, tempFolder: TempFolder) {
        self.deployerConfiguration = deployerConfiguration
        self.generator = DeployablesGenerator(
            targetAvitoRunnerPath: DistRunDeployer.avitoRunnerTargetPath,
            pluginLocations: deployerConfiguration.pluginLocations
        )
        self.tempFolder = tempFolder
    }
    
    public func deployAndStartWorkersOnRemoteDestinations() throws {
        try deployWorkersToRemoteDestinations()
        try startWorkersOnRemoteDestinations()
    }
    
    public func deployWorkersToRemoteDestinations() throws {
        let deployables = try generator.deployables()
        let deployer = try SSHDeployer(
            sshClientType: DefaultSSHClient.self,
            deploymentId: deployerConfiguration.runId,
            deployables: deployables.values.flatMap { $0 },
            deployableCommands: [],
            destinations: deployerConfiguration.deploymentDestinations
        )
        try deployer.deploy()
    }

    public func startWorkersOnRemoteDestinations() throws {
        let launchdPlistTargetPath = "launchd.plist"
        
        try deployerConfiguration.deploymentDestinations.forEach { destination in
            let plistData = try launchdPlistDataForStartingEmceeRemotely(deploymentDestination: destination)
            let filePath = try tempFolder.createFile(filename: launchdPlistTargetPath, contents: plistData)
            
            let launchdDeployableItem = DeployableItem(
                name: "launchd_plist",
                files: [DeployableFile(source: filePath.asString, destination: launchdPlistTargetPath)]
            )
            
            let deployer = try SSHDeployer(
                sshClientType: DefaultSSHClient.self,
                deploymentId: deployerConfiguration.runId,
                deployables: [launchdDeployableItem],
                deployableCommands: [
                    [
                        "launchctl", "unload",
                        "-w", "-S", "Background",
                        .item(launchdDeployableItem, relativePath: launchdPlistTargetPath)
                    ],
                    [
                        "sleep", "2"        // launchctl is async, so we have to wait :(
                    ],
                    [
                        "launchctl", "load",
                        "-w", "-S", "Background",
                        .item(launchdDeployableItem, relativePath: launchdPlistTargetPath)
                    ]
                ],
                destinations: [destination]
            )
            do {
                try deployer.deploy()
            } catch {
                log("Failed to deploy launchd plist: \(error). This error will be ignored.", color: .yellow)
            }
        }
    }
    
    private func launchdPlistDataForStartingEmceeRemotely(deploymentDestination: DeploymentDestination) throws -> Data {
        let avitoRunnerContainerPath = SSHDeployer.remoteContainerPath(
            forDeployable: generator.runnerTool,
            destination: deploymentDestination,
            deploymentId: deployerConfiguration.runId
        )
        let remoteAvitoRunnerPath = avitoRunnerContainerPath.appending(pathComponent: DistRunDeployer.avitoRunnerTargetPath)
        let jobLabel = "ru.avito.UITestsRunner.\(deployerConfiguration.runId.removingWhitespaces())"
        let launchdPlist = LaunchdPlist(job:
            LaunchdJob(
                label: jobLabel,
                programArguments: [
                    remoteAvitoRunnerPath, "distWork",
                    "--queue-server", "\(deployerConfiguration.queueServerHost):\(deployerConfiguration.queueServerPort)",
                    "--worker-id", deploymentDestination.identifier
                ],
                environmentVariables: [:],
                workingDirectory: avitoRunnerContainerPath,
                runAtLoad: true,
                disabled: true,
                standardOutPath: avitoRunnerContainerPath.appending(pathComponent: "stdout.txt"),
                standardErrorPath: avitoRunnerContainerPath.appending(pathComponent: "stderr.txt"),
                sockets: [:],
                inetdCompatibility: .disabled,
                sessionType: .background
            )
        )
        return try launchdPlist.createPlistData()
    }
}
