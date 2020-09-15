import ArgLib
import BucketQueue
import DI
import DateProvider
import Deployer
import DeveloperDirLocator
import DistDeployer
import EmceeVersion
import FileSystem
import Foundation
import Logging
import LoggingSetup
import Metrics
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
import SocketModels
import SynchronousWaiter
import TemporaryStuff
import TestArgFile
import TestDiscovery
import Types
import UniqueIdentifierGenerator

public final class RunTestsOnRemoteQueueCommand: Command {
    public let name = "runTestsOnRemoteQueue"
    public let description = "Starts queue server on remote machine if needed and runs tests on the remote queue. Waits for resuls to come back."
    public let arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asOptional,
        ArgumentDescriptions.junit.asOptional,
        ArgumentDescriptions.queueServerConfigurationLocation.asRequired,
        ArgumentDescriptions.remoteCacheConfig.asOptional,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.trace.asOptional,
    ]
    
    private let callbackQueue = DispatchQueue(label: "RunTestsOnRemoteQueueCommand.callbackQueue")
    private let di: DI
    private let testArgFileValidator = TestArgFileValidator()
    private let waiter = SynchronousWaiter()
    
    public init(di: DI) {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let commonReportOutput = ReportOutput(
            junit: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.junit.name),
            tracingReport: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.trace.name)
        )

        let queueServerConfigurationLocation: QueueServerConfigurationLocation = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerConfigurationLocation.name)
        let queueServerConfiguration = try ArgumentsReader.queueServerConfiguration(
            location: queueServerConfigurationLocation,
            resourceLocationResolver: try di.get()
        )

        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        let tempFolder = try TemporaryFolder(containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name))
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        try testArgFileValidator.validate(testArgFile: testArgFile)

        let remoteCacheConfig = try ArgumentsReader.remoteCacheConfig(
            try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.remoteCacheConfig.name)
        )
        
        di.set(tempFolder, for: TemporaryFolder.self)

        let runningQueueServerAddress = try detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
            emceeVersion: emceeVersion,
            queueServerDeploymentDestination: queueServerConfiguration.queueServerDeploymentDestination,
            queueServerConfigurationLocation: queueServerConfigurationLocation,
            jobId: testArgFile.jobId
        )
        let jobResults = try runTestsOnRemotelyRunningQueue(
            queueServerAddress: runningQueueServerAddress,
            remoteCacheConfig: remoteCacheConfig,
            testArgFile: testArgFile,
            version: emceeVersion
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
        queueServerDeploymentDestination: DeploymentDestination,
        queueServerConfigurationLocation: QueueServerConfigurationLocation,
        jobId: JobId
    ) throws -> SocketAddress {
        Logger.info("Searching for queue server on '\(queueServerDeploymentDestination.host)' with queue version \(emceeVersion)")
        let remoteQueueDetector = DefaultRemoteQueueDetector(
            emceeVersion: emceeVersion,
            remotePortDeterminer: RemoteQueuePortScanner(
                host: queueServerDeploymentDestination.host,
                portRange: EmceePorts.defaultQueuePortRange,
                requestSenderProvider: try di.get()
            )
        )
        var suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10)
        if !suitablePorts.isEmpty {
            let socketAddress = SocketAddress(
                host: queueServerDeploymentDestination.host,
                port: try selectPort(ports: suitablePorts)
            )
            Logger.info("Found queue server at '\(socketAddress)'")
            return socketAddress
        }
        
        try startNewInstanceOfRemoteQueueServer(
            jobId: jobId,
            queueServerDeploymentDestination: queueServerDeploymentDestination,
            emceeVersion: emceeVersion,
            queueServerConfigurationLocation: queueServerConfigurationLocation
        )
        
        try waiter.waitWhile(pollPeriod: 1.0, timeout: 30.0, description: "Wait for remote queue to start") {
            suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10)
            return suitablePorts.isEmpty
        }
        
        let queueServerAddress = SocketAddress(
            host: queueServerDeploymentDestination.host,
            port: try selectPort(ports: suitablePorts)
        )
        Logger.info("Found queue server at '\(queueServerAddress)'")

        return queueServerAddress
    }
    
    private func startNewInstanceOfRemoteQueueServer(
        jobId: JobId,
        queueServerDeploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation
    ) throws {
        Logger.info("No running queue server has been found. Will deploy and start remote queue.")
        let remoteQueueStarter = RemoteQueueStarter(
            deploymentId: jobId.value,
            deploymentDestination: queueServerDeploymentDestination,
            emceeVersion: emceeVersion,
            processControllerProvider: try di.get(),
            queueServerConfigurationLocation: queueServerConfigurationLocation,
            tempFolder: try di.get(),
            uniqueIdentifierGenerator: try di.get()
        )
        try remoteQueueStarter.deployAndStart()
    }
    
    private func runTestsOnRemotelyRunningQueue(
        queueServerAddress: SocketAddress,
        remoteCacheConfig: RuntimeDumpRemoteCacheConfig?,
        testArgFile: TestArgFile,
        version: Version
    ) throws -> JobResults {
        let metricRecorder: MutableMetricRecorder = try di.get()
        try metricRecorder.set(analyticsConfiguration: testArgFile.analyticsConfiguration)
        if let sentryConfiguration = testArgFile.analyticsConfiguration.sentryConfiguration {
            try AnalyticsSetup.setupSentry(sentryConfiguration: sentryConfiguration, emceeVersion: version)
        }
        
        let onDemandSimulatorPool = try OnDemandSimulatorPoolFactory.create(
            di: di,
            version: version,
            metricRecorder: metricRecorder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        di.set(onDemandSimulatorPool, for:OnDemandSimulatorPool.self)
        
        let testDiscoveryQuerier = TestDiscoveryQuerierImpl(
            dateProvider: try di.get(),
            developerDirLocator: try di.get(),
            fileSystem: try di.get(),
            onDemandSimulatorPool: try di.get(),
            pluginEventBusProvider: try di.get(),
            processControllerProvider: try di.get(),
            resourceLocationResolver: try di.get(),
            tempFolder: try di.get(),
            testRunnerProvider: try di.get(),
            uniqueIdentifierGenerator: try di.get(),
            version: version,
            metricRecorder: metricRecorder
        )
        
        let queueClient = SynchronousQueueClient(queueServerAddress: queueServerAddress)
        
        defer {
            Logger.info("Will delete job \(testArgFile.jobId)")
            do {
                _ = try queueClient.delete(jobId: testArgFile.jobId)
            } catch {
                Logger.error("Failed to delete job \(testArgFile.jobId): \(error)")
            }
        }

        let testEntriesValidator = TestEntriesValidator(
            remoteCache: try di.get(RuntimeDumpRemoteCacheProvider.self).remoteCache(config: remoteCacheConfig),
            testArgFileEntries: testArgFile.entries,
            testDiscoveryQuerier: testDiscoveryQuerier,
            persistentMetricsJobId: testArgFile.persistentMetricsJobId
        )
        
        _ = try testEntriesValidator.validatedTestEntries { testArgFileEntry, validatedTestEntry in
            let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
                validatedEntries: validatedTestEntry,
                testArgFileEntry: testArgFileEntry,
                persistentMetricsJobId: testArgFile.persistentMetricsJobId
            )
            let testEntryConfigurations = testEntryConfigurationGenerator.createTestEntryConfigurations()
            Logger.info("Will schedule \(testEntryConfigurations.count) tests to queue server at \(queueServerAddress)")
            
            let testScheduler = TestSchedulerImpl(
                requestSender: try di.get(RequestSenderProvider.self).requestSender(socketAddress: queueServerAddress)
            )
            
            let callbackWaiter: CallbackWaiter<Either<Void, Error>> = waiter.createCallbackWaiter()
            testScheduler.scheduleTests(
                prioritizedJob: PrioritizedJob(
                    jobGroupId: testArgFile.jobGroupId,
                    jobGroupPriority: testArgFile.jobGroupPriority,
                    jobId: testArgFile.jobId,
                    jobPriority: testArgFile.jobPriority,
                    persistentMetricsJobId: testArgFile.persistentMetricsJobId
                ),
                scheduleStrategy: testArgFileEntry.scheduleStrategy,
                testEntryConfigurations: testEntryConfigurations,
                callbackQueue: callbackQueue,
                completion: callbackWaiter.set
            )
            try callbackWaiter.wait(timeout: 60, description: "Schedule tests").dematerialize()
        }
        
        var caughtSignal = false
        SignalHandling.addSignalHandler(signals: [.int, .term]) { signal in
            Logger.info("Caught \(signal) signal")
            Logger.info("Will delete job \(testArgFile.jobId)")
            _ = try? queueClient.delete(jobId: testArgFile.jobId)
            caughtSignal = true
        }
        
        Logger.info("Will now wait for job queue to deplete")
        try waiter.waitWhile(pollPeriod: 30.0, description: "Wait for job queue to deplete") {
            if caughtSignal { return false }
            let jobState = try queueClient.jobState(jobId: testArgFile.jobId)
            switch jobState.queueState {
            case .deleted:
                return false
            case .running(let runningQueueState):
                BucketQueueStateLogger(runningQueueState: runningQueueState).logQueueSize()
                return !runningQueueState.isDepleted
            }
        }
        Logger.info("Will now fetch job results")
        return try queueClient.jobResults(jobId: testArgFile.jobId)
    }
    
    private func selectPort(ports: Set<SocketModels.Port>) throws -> SocketModels.Port {
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
