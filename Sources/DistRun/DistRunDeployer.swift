import Foundation
import Deployer
import Models
import ScheduleStrategy
import SSHDeployer
import TempFolder
import LaunchdUtils
import HostDeterminer
import Logging

public final class DistRunDeployer {
    
    private let distRunConfiguration: DistRunConfiguration
    private let tempFolder: TempFolder
    private let avitoRunnerTargetPath = "AvitoRunner"
    private let launchdPlistTargetPath = "launchd.plist"

    public init(distRunConfiguration: DistRunConfiguration, tempFolder: TempFolder) {
        self.distRunConfiguration = distRunConfiguration
        self.tempFolder = tempFolder
    }
    
    public enum DistRunnerError: Error {
        case runtimeDumpMissesSomeTests([TestToRun])
        case runtimeDumpHasZeroTests
        case avitoRunnerDeployableItemIsMissing
        case multipleBuildArtifactsAreNotSupported(Set<BuildArtifacts>)
    }
    
    public func deployAndStartLaunchdJob(serverPort: Int) throws {        
        let buildArtifacts = Set(distRunConfiguration.testEntryConfigurations.map { $0.buildArtifacts })
        guard buildArtifacts.count == 1, let buildArtifact = buildArtifacts.first else {
            throw DistRunnerError.multipleBuildArtifactsAreNotSupported(buildArtifacts)
        }
        
        let generator = DeployablesGenerator(
            targetAvitoRunnerPath: avitoRunnerTargetPath,
            auxiliaryResources: distRunConfiguration.auxiliaryResources,
            buildArtifacts: buildArtifact,
            simulatorSettings: distRunConfiguration.simulatorSettings,
            targetSimulatorLocalizationSettingsPath: try PackageName.targetFileName(.simulatorLocalizationSettings),
            targetWatchdogSettingsPath: try PackageName.targetFileName(.watchdogSettings))
        let deployables = try generator.deployables()
        
        let deployer = try SSHDeployer(
            sshClientType: DefaultSSHClient.self,
            deploymentId: distRunConfiguration.runId,
            deployables: deployables.values.flatMap { $0 },
            deployableCommands: [],
            destinations: distRunConfiguration.destinations)
        try deployer.deploy()
        
        guard let avitoRunnerDeployable = deployables[.avitoRunner]?.first else {
            throw DistRunnerError.avitoRunnerDeployableItemIsMissing
        }
        try deployLaunchdPlist(avitoRunnerDeployable: avitoRunnerDeployable, serverPort: serverPort)
    }
    
    private func launchdPlistData(
        destination: DeploymentDestination,
        avitoRunnerDeployable: DeployableItem,
        serverPort: Int) throws -> Data
    {
        let avitoRunnerContainerPath = SSHDeployer.remoteContainerPath(
            forDeployable: avitoRunnerDeployable,
            destination: destination,
            deploymentId: distRunConfiguration.runId)
        let remoteAvitoRunnerPath = avitoRunnerContainerPath.appending(pathComponent: avitoRunnerTargetPath)
        let jobLabel = "ru.avito.UITestsRunner.\(distRunConfiguration.runId.removingWhitespaces())"
        let launchdJob = LaunchdJob(
            label: jobLabel,
            programArguments: [
                remoteAvitoRunnerPath, "distWork",
                "--queue-server", "\(HostDeterminer.currentHostAddress):\(serverPort)",
                "--worker-id", destination.identifier
            ],
            environmentVariables: [:],
            workingDirectory: avitoRunnerContainerPath,
            runAtLoad: true,
            disabled: true,
            standardOutPath: avitoRunnerContainerPath.appending(pathComponent: "stdout.txt"),
            standardErrorPath: avitoRunnerContainerPath.appending(pathComponent: "stderr.txt"),
            sockets: [:],
            inetdCompatibility: .disabled,
            sessionType: .background)
        let launchdPlist = LaunchdPlist(job: launchdJob)
        let data = try launchdPlist.createPlistData()
        return data
    }
    
    private func deployLaunchdPlist(avitoRunnerDeployable: DeployableItem, serverPort: Int) throws {
        try distRunConfiguration.destinations.forEach { destination in
            let plistData = try launchdPlistData(
                destination: destination,
                avitoRunnerDeployable: avitoRunnerDeployable,
                serverPort: serverPort)
            
            let filePath = try tempFolder.createFile(filename: launchdPlistTargetPath, contents: plistData)
            
            let lauchdDeployableItem = DeployableItem(
                name: "launchd_plist",
                files: [DeployableFile(source: filePath.asString, destination: launchdPlistTargetPath)])
            
            let deployer = try SSHDeployer(
                sshClientType: DefaultSSHClient.self,
                deploymentId: distRunConfiguration.runId,
                deployables: [lauchdDeployableItem],
                deployableCommands: [
                    [
                        "launchctl", "unload",
                        "-w", "-S", "Background",
                        .item(lauchdDeployableItem, relativePath: launchdPlistTargetPath)
                    ],
                    [
                        "sleep", "2"        // launchctl is async, so we have to wait :(
                    ],
                    [
                        "launchctl", "load",
                        "-w", "-S", "Background",
                        .item(lauchdDeployableItem, relativePath: launchdPlistTargetPath)
                    ],
                    ],
                destinations: [destination])
            do {
                try deployer.deploy()
            } catch {
                log("Failed to deploy launchd plist: \(error). This error will be ignored.", color: .yellow)
            }
        }
    }
}
