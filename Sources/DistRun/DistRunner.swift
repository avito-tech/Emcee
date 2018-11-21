import Basic
import Deployer
import EventBus
import Extensions
import Foundation
import HostDeterminer
import LaunchdUtils
import Logging
import Models
import ResourceLocationResolver
import RESTMethods
import RuntimeDump
import SSHDeployer
import ScheduleStrategy
import TempFolder

public final class DistRunner {
    
    public enum DistRunnerError: Error {
        case runtimeDumpMissesSomeTests([TestToRun])
        case runtimeDumpHasZeroTests
        case avitoRunnerDeployableItemIsMissing
    }
    
    private let eventBus: EventBus
    private let distRunConfiguration: DistRunConfiguration
    private let tempFolder: TempFolder
    private let resourceLocationResolver: ResourceLocationResolver
    private let avitoRunnerTargetPath = "AvitoRunner"
    private let launchdPlistTargetPath = "launchd.plist"
    
    public init(
        eventBus: EventBus,
        distRunConfiguration: DistRunConfiguration,
        resourceLocationResolver: ResourceLocationResolver) throws
    {
        self.eventBus = eventBus
        self.distRunConfiguration = distRunConfiguration
        self.tempFolder = try TempFolder()
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func run() throws -> [TestingResult] {
        let queueServer = QueueServer(
            eventBus: eventBus,
            workerConfigurations: createWorkerConfigurations(),
            reportAliveInterval: distRunConfiguration.reportAliveInterval)
        queueServer.add(buckets: try prepareQueue())
        let port = try queueServer.start()
        try deployAndStartLaunchdJob(serverPort: port)
        return try queueServer.waitForQueueToFinish()
    }
    
    private func prepareQueue() throws -> [Bucket] {
        let transformer = TestToRunIntoTestEntryTransformer(
            eventBus: eventBus,
            configuration: RuntimeDumpConfiguration.fromDistRunConfiguration(distRunConfiguration),
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver)
        let testEntries = try transformer.transform().avito_shuffled()
        
        let buckets = BucketsGenerator.generateBuckets(
            strategy: distRunConfiguration.remoteScheduleStrategyType.scheduleStrategy(),
            numberOfDestinations: UInt(distRunConfiguration.destinations.count),
            testEntries: testEntries,
            testDestinations: distRunConfiguration.testDestinations,
            toolResources: distRunConfiguration.auxiliaryResources.toolResources,
            buildArtifacts: distRunConfiguration.buildArtifacts)
        return buckets
    }
    
    private func createWorkerConfigurations() -> WorkerConfigurations {
        let configurations = WorkerConfigurations()
        for destination in distRunConfiguration.destinations {
            configurations.add(
                workerId: destination.identifier,
                configuration: distRunConfiguration.workerConfiguration(destination: destination))
        }
        return configurations
    }
    
    private func deployAndStartLaunchdJob(serverPort: Int) throws  {
        let encoder = JSONEncoder()
        let encodedEnvironment = try encoder.encode(distRunConfiguration.testExecutionBehavior.environment)
        let environmentFilePath = try tempFolder.createFile(filename: "envirtonment.json", contents: encodedEnvironment)
        
        let generator = DeployablesGenerator(
            targetAvitoRunnerPath: avitoRunnerTargetPath,
            auxiliaryResources: distRunConfiguration.auxiliaryResources,
            buildArtifacts: distRunConfiguration.buildArtifacts,
            environmentFilePath: environmentFilePath.asString,
            targetEnvironmentPath: try PackageName.targetFileName(.environment),
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
            environmentVariables: distRunConfiguration.testExecutionBehavior.environment,
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
