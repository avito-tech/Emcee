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
import EmceeLogging
import LoggingSetup
import Metrics
import MetricsExtensions
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
import Tmp
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
        ArgumentDescriptions.tempFolder.asOptional,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.trace.asOptional,
    ]
    
    private let callbackQueue = DispatchQueue(label: "RunTestsOnRemoteQueueCommand.callbackQueue")
    private let di: DI
    private let testArgFileValidator = TestArgFileValidator()
    
    public init(di: DI) throws {
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
        let tempFolder = try TemporaryFolder(containerPath: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name))
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        try testArgFileValidator.validate(testArgFile: testArgFile)
        
        if let kibanaConfiguration = testArgFile.prioritizedJob.analyticsConfiguration.kibanaConfiguration {
            try di.get(LoggingSetup.self).set(kibanaConfiguration: kibanaConfiguration)
        }
        try di.get(GlobalMetricRecorder.self).set(
            analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration
        )
        di.set(
            try di.get(ContextualLogger.self).with(
                analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration
            )
        )
        let logger = try di.get(ContextualLogger.self)

        let remoteCacheConfig = try ArgumentsReader.remoteCacheConfig(
            try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.remoteCacheConfig.name)
        )
        
        di.set(tempFolder, for: TemporaryFolder.self)

        let runningQueueServerAddress = try detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
            emceeVersion: emceeVersion,
            queueServerDeploymentDestination: queueServerConfiguration.queueServerDeploymentDestination,
            queueServerConfigurationLocation: queueServerConfigurationLocation,
            jobId: testArgFile.prioritizedJob.jobId,
            logger: logger
        )
        let jobResults = try runTestsOnRemotelyRunningQueue(
            queueServerAddress: runningQueueServerAddress,
            remoteCacheConfig: remoteCacheConfig,
            testArgFile: testArgFile,
            version: emceeVersion,
            logger: logger
        )
        let resultOutputGenerator = ResultingOutputGenerator(
            logger: logger,
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
        jobId: JobId,
        logger: ContextualLogger
    ) throws -> SocketAddress {
        logger.info("Searching for queue server on '\(queueServerDeploymentDestination.host)' with queue version \(emceeVersion)")
        let remoteQueueDetector = DefaultRemoteQueueDetector(
            emceeVersion: emceeVersion,
            logger: logger,
            remotePortDeterminer: RemoteQueuePortScanner(
                hosts: [queueServerDeploymentDestination.host],
                logger: logger,
                portRange: EmceePorts.defaultQueuePortRange,
                requestSenderProvider: try di.get()
            )
        )
        var suitableAddresses = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10)
        if !suitableAddresses.isEmpty {
            logger.info("Found \(suitableAddresses.count) queue server(s) at '\(suitableAddresses)'")
            return try selectAddress(addresses: suitableAddresses)
        }
        
        try startNewInstanceOfRemoteQueueServer(
            jobId: jobId,
            queueServerDeploymentDestination: queueServerDeploymentDestination,
            emceeVersion: emceeVersion,
            queueServerConfigurationLocation: queueServerConfigurationLocation,
            logger: logger
        )
        
        try di.get(Waiter.self).waitWhile(pollPeriod: 1.0, timeout: 30.0, description: "Wait for remote queue to start") {
            suitableAddresses = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10)
            return suitableAddresses.isEmpty
        }
        
        let queueServerAddress = try selectAddress(addresses: suitableAddresses)
        logger.info("Using queue server at '\(queueServerAddress)'")
        return queueServerAddress
    }
    
    private func startNewInstanceOfRemoteQueueServer(
        jobId: JobId,
        queueServerDeploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation,
        logger: ContextualLogger
    ) throws {
        logger.info("No running queue server has been found. Will deploy and start remote queue.")
        let remoteQueueStarter = RemoteQueueStarter(
            deploymentId: jobId.value,
            deploymentDestination: queueServerDeploymentDestination,
            emceeVersion: emceeVersion,
            logger: logger,
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
        version: Version,
        logger: ContextualLogger
    ) throws -> JobResults {
        let onDemandSimulatorPool = try OnDemandSimulatorPoolFactory.create(
            di: di,
            logger: logger,
            version: version
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        di.set(onDemandSimulatorPool, for: OnDemandSimulatorPool.self)
        di.set(
            TestDiscoveryQuerierImpl(
                dateProvider: try di.get(),
                developerDirLocator: try di.get(),
                fileSystem: try di.get(),
                globalMetricRecorder: try di.get(),
                specificMetricRecorderProvider: try di.get(),
                onDemandSimulatorPool: try di.get(),
                pluginEventBusProvider: try di.get(),
                processControllerProvider: try di.get(),
                resourceLocationResolver: try di.get(),
                runnerWasteCollectorProvider: try di.get(),
                tempFolder: try di.get(),
                testRunnerProvider: try di.get(),
                uniqueIdentifierGenerator: try di.get(),
                version: version,
                waiter: try di.get()
            ),
            for: TestDiscoveryQuerier.self
        )
        di.set(
            JobStateFetcherImpl(
                requestSender: try di.get(RequestSenderProvider.self).requestSender(socketAddress: queueServerAddress)
            ),
            for: JobStateFetcher.self
        )
        di.set(
            JobResultsFetcherImpl(
                requestSender: try di.get(RequestSenderProvider.self).requestSender(socketAddress: queueServerAddress)
            ),
            for: JobResultsFetcher.self
        )
        di.set(
            JobDeleterImpl(
                requestSender: try di.get(RequestSenderProvider.self).requestSender(socketAddress: queueServerAddress)
            ),
            for: JobDeleter.self
        )
        
        defer {
            deleteJob(jobId: testArgFile.prioritizedJob.jobId, logger: logger)
        }
        
        try JobPreparer(di: di).formJob(
            emceeVersion: version,
            queueServerAddress: queueServerAddress,
            remoteCacheConfig: remoteCacheConfig,
            testArgFile: testArgFile
        )
        
        try waitForJobQueueToDeplete(jobId: testArgFile.prioritizedJob.jobId, logger: logger)
        return try fetchJobResults(jobId: testArgFile.prioritizedJob.jobId)
    }
    
    private func waitForJobQueueToDeplete(jobId: JobId, logger: ContextualLogger) throws {
        var caughtSignal = false
        SignalHandling.addSignalHandler(signals: [.int, .term]) { [logger] signal in
            logger.info("Caught \(signal) signal")
            caughtSignal = true
        }
        
        try di.get(Waiter.self).waitWhile(pollPeriod: 30.0, description: "Waiting for job queue to deplete") {
            if caughtSignal { return false }
            
            let state = try fetchJobState(jobId: jobId)
            switch state.queueState {
            case .deleted:
                return false
            case .running(let queueState):
                BucketQueueStateLogger(runningQueueState: queueState, logger: logger).printQueueSize()
                return !queueState.isDepleted
            }
        }
    }
    
    private func fetchJobResults(jobId: JobId) throws -> JobResults {
        let callbackWaiter: CallbackWaiter<Either<JobResults, Error>> = try di.get(Waiter.self).createCallbackWaiter()
        try di.get(JobResultsFetcher.self).fetch(
            jobId: jobId,
            callbackQueue: callbackQueue,
            completion: callbackWaiter.set
        )
        return try callbackWaiter.wait(timeout: .infinity, description: "Fetching job results").dematerialize()
    }
    
    private func fetchJobState(jobId: JobId) throws -> JobState {
        let callbackWaiter: CallbackWaiter<Either<JobState, Error>> =  try di.get(Waiter.self).createCallbackWaiter()
        try di.get(JobStateFetcher.self).fetch(
            jobId: jobId,
            callbackQueue: callbackQueue,
            completion: callbackWaiter.set
        )
        return try callbackWaiter.wait(timeout: .infinity, description: "Fetch job state").dematerialize()
    }
    
    private func selectAddress(addresses: Set<SocketAddress>) throws -> SocketAddress {
        struct NoRunningQueueFoundError: Error, CustomStringConvertible {
            var description: String { "No running queue server found" }
        }
        
        guard let address = addresses.sorted().last else { throw NoRunningQueueFoundError() }
        return address
    }
    
    private func deleteJob(jobId: JobId, logger: ContextualLogger) {
        do {
            let callbackWaiter: CallbackWaiter<Either<(), Error>> = try di.get(Waiter.self).createCallbackWaiter()
            try di.get(JobDeleter.self).delete(
                jobId: jobId,
                callbackQueue: callbackQueue,
                completion: callbackWaiter.set
            )
            try callbackWaiter.wait(timeout: .infinity, description: "Deleting job").dematerialize()
        } catch {
            logger.warning("Failed to delete job")
        }
    }
}

extension SocketAddress: Comparable {
    public static func < (lhs: SocketAddress, rhs: SocketAddress) -> Bool {
        lhs.asString < rhs.asString
    }
}
