import ArgLib
import BucketQueue
import DateProvider
import Deployer
import DeveloperDirLocator
import DistDeployer
import Extensions
import FileSystem
import Foundation
import Logging
import LoggingSetup
import Models
import PathLib
import PluginManager
import PortDeterminer
import ProcessController
import QueueClient
import QueueCommunication
import QueueModels
import QueueServer
import RemotePortDeterminer
import RequestSender
import ResourceLocationResolver
import SignalHandling
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff
import TestArgFile
import TestDiscovery
import UniqueIdentifierGenerator

public final class RunTestsOnRemoteQueueCommand: Command {
    public let name = "runTestsOnRemoteQueue"
    public let description = "Starts queue server on remote machine if needed and runs tests on the remote queue. Waits for resuls to come back."
    public let arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asRequired,
        ArgumentDescriptions.jobGroupId.asOptional,
        ArgumentDescriptions.jobGroupPriority.asOptional,
        ArgumentDescriptions.jobId.asRequired,
        ArgumentDescriptions.junit.asOptional,
        ArgumentDescriptions.queueServerDestination.asRequired,
        ArgumentDescriptions.queueServerRunConfigurationLocation.asRequired,
        ArgumentDescriptions.remoteCacheConfig.asOptional,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.trace.asOptional,
    ]
    
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let pluginEventBusProvider: PluginEventBusProvider
    private let processControllerProvider: ProcessControllerProvider
    private let requestSenderProvider: RequestSenderProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let runtimeDumpRemoteCacheProvider: RuntimeDumpRemoteCacheProvider
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        pluginEventBusProvider: PluginEventBusProvider,
        processControllerProvider: ProcessControllerProvider,
        requestSenderProvider: RequestSenderProvider,
        resourceLocationResolver: ResourceLocationResolver,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        runtimeDumpRemoteCacheProvider: RuntimeDumpRemoteCacheProvider
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.pluginEventBusProvider = pluginEventBusProvider
        self.processControllerProvider = processControllerProvider
        self.requestSenderProvider = requestSenderProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.runtimeDumpRemoteCacheProvider = runtimeDumpRemoteCacheProvider
    }
    
    public func run(payload: CommandPayload) throws {
        let commonReportOutput = ReportOutput(
            junit: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.junit.name),
            tracingReport: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.trace.name)
        )
        
        let queueServerDestination = try ArgumentsReader.deploymentDestinations(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerDestination.name)
        ).elementAtIndex(0, "first and single queue server destination")
        
        let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerRunConfigurationLocation.name)
        let jobId: JobId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.jobId.name)
        let jobGroupId: JobGroupId = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.jobGroupId.name) ?? JobGroupId(value: jobId.value)
        let emceeVersion: Version = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name)
        
        let tempFolder = try TemporaryFolder(containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name))
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        let jobGroupPriority: Priority = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.jobGroupPriority.name) ?? testArgFile.priority

        let remoteCacheConfig = try ArgumentsReader.remoteCacheConfig(
            try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.remoteCacheConfig.name)
        )

        let runningQueueServerAddress = try detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
            emceeVersion: emceeVersion,
            queueServerDestination: queueServerDestination,
            queueServerRunConfigurationLocation: queueServerRunConfigurationLocation,
            jobId: jobId,
            tempFolder: tempFolder
        )
        let jobResults = try runTestsOnRemotelyRunningQueue(
            queueServerAddress: runningQueueServerAddress,
            jobGroupId: jobGroupId,
            jobGroupPriority: jobGroupPriority,
            jobId: jobId,
            tempFolder: tempFolder,
            testArgFile: testArgFile,
            remoteCacheConfig: remoteCacheConfig
        )
        let resultOutputGenerator = ResultingOutputGenerator(
            testingResults: jobResults.testingResults,
            commonReportOutput: commonReportOutput,
            testDestinationConfigurations: testArgFile.testDestinationConfigurations
        )
        try resultOutputGenerator.generateOutput()
    }
    
    private func detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
        emceeVersion: Version,
        queueServerDestination: DeploymentDestination,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        jobId: JobId,
        tempFolder: TemporaryFolder
    ) throws -> SocketAddress {
        Logger.info("Searching for queue server on '\(queueServerDestination.host)' with queue version \(emceeVersion)")
        let remoteQueueDetector = DefaultRemoteQueueDetector(
            emceeVersion: emceeVersion,
            remotePortDeterminer: RemoteQueuePortScanner(
                host: queueServerDestination.host,
                portRange: Ports.defaultQueuePortRange,
                requestSenderProvider: requestSenderProvider
            )
        )
        var suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10)
        if !suitablePorts.isEmpty {
            let socketAddress = SocketAddress(
                host: queueServerDestination.host,
                port: try selectPort(ports: suitablePorts)
            )
            Logger.info("Found queue server at '\(socketAddress)'")
            return socketAddress
        }
        
        Logger.info("No running queue server has been found. Will deploy and start remote queue.")
        let remoteQueueStarter = RemoteQueueStarter(
            deploymentId: jobId.value,
            deploymentDestination: queueServerDestination,
            emceeVersion: emceeVersion,
            processControllerProvider: processControllerProvider,
            queueServerRunConfigurationLocation: queueServerRunConfigurationLocation,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        let deployQueue = DispatchQueue(label: "RunTestsOnRemoteQueueCommand.deployQueue", attributes: .concurrent)
        try remoteQueueStarter.deployAndStart(deployQueue: deployQueue)
        
        try SynchronousWaiter().waitWhile(pollPeriod: 1.0, timeout: 30.0, description: "Wait for remote queue to start") {
            suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10)
            return suitablePorts.isEmpty
        }
        
        let queueServerAddress = SocketAddress(
            host: queueServerDestination.host,
            port: try selectPort(ports: suitablePorts)
        )
        Logger.info("Found queue server at '\(queueServerAddress)'")

        return queueServerAddress
    }
    
    private func runTestsOnRemotelyRunningQueue(
        queueServerAddress: SocketAddress,
        jobGroupId: JobGroupId,
        jobGroupPriority: Priority,
        jobId: JobId,
        tempFolder: TemporaryFolder,
        testArgFile: TestArgFile,
        remoteCacheConfig: RuntimeDumpRemoteCacheConfig?
    ) throws -> JobResults {
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        let testDiscoveryQuerier = TestDiscoveryQuerierImpl(
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            numberOfAttemptsToPerformRuntimeDump: 5,
            onDemandSimulatorPool: onDemandSimulatorPool,
            pluginEventBusProvider: pluginEventBusProvider,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: DefaultTestRunnerProvider(
                dateProvider: dateProvider,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver
            ),
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator(),
            remoteCache: runtimeDumpRemoteCacheProvider.remoteCache(config: remoteCacheConfig)
        )
        
        let queueClient = SynchronousQueueClient(queueServerAddress: queueServerAddress)
        
        defer {
            Logger.info("Will delete job \(jobId)")
            do {
                _ = try queueClient.delete(jobId: jobId)
            } catch {
                Logger.error("Failed to delete job \(jobId): \(error)")
            }
        }

        let testEntriesValidator = TestEntriesValidator(
            testArgFileEntries: testArgFile.entries,
            testDiscoveryQuerier: testDiscoveryQuerier
        )
        
        _ = try testEntriesValidator.validatedTestEntries { testArgFileEntry, validatedTestEntry in
            let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
                validatedEntries: validatedTestEntry,
                testArgFileEntry: testArgFileEntry
            )
            let testEntryConfigurations = testEntryConfigurationGenerator.createTestEntryConfigurations()
            Logger.info("Will schedule \(testEntryConfigurations.count) tests to queue server at \(queueServerAddress)")
            
            do {
                _ = try queueClient.scheduleTests(
                    prioritizedJob: PrioritizedJob(
                        jobGroupId: jobGroupId,
                        jobGroupPriority: jobGroupPriority,
                        jobId: jobId,
                        jobPriority: testArgFile.priority
                    ),
                    scheduleStrategy: testArgFileEntry.scheduleStrategy,
                    testEntryConfigurations: testEntryConfigurations,
                    requestId: RequestId(value: jobId.value + "_" + UUID().uuidString)
                )
            } catch {
                Logger.error("Failed to schedule tests: \(error)")
                throw error
            }
        }
        
        var caughtSignal = false
        SignalHandling.addSignalHandler(signals: [.int, .term]) { signal in
            Logger.info("Caught \(signal) signal")
            Logger.info("Will delete job \(jobId)")
            _ = try? queueClient.delete(jobId: jobId)
            caughtSignal = true
        }
        
        Logger.info("Will now wait for job queue to deplete")
        try SynchronousWaiter().waitWhile(pollPeriod: 30.0, description: "Wait for job queue to deplete") {
            if caughtSignal { return false }
            let jobState = try queueClient.jobState(jobId: jobId)
            switch jobState.queueState {
            case .deleted:
                return false
            case .running(let runningQueueState):
                BucketQueueStateLogger(runningQueueState: runningQueueState).logQueueSize()
                return !runningQueueState.isDepleted
            }
        }
        Logger.info("Will now fetch job results")
        return try queueClient.jobResults(jobId: jobId)
    }
    
    private func selectPort(ports: Set<Models.Port>) throws -> Models.Port {
        enum PortScanningError: Error, CustomStringConvertible {
            case noQueuePortDetected
            
            var description: String {
                switch self {
                case .noQueuePortDetected:
                    return "No running queue server found"
                }
            }
        }
        
        guard let port = ports.sorted().last else { throw PortScanningError.noQueuePortDetected }
        return port
    }
}
