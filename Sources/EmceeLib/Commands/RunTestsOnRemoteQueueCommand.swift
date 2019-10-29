import ArgLib
import BucketQueue
import DeveloperDirLocator
import DistDeployer
import EventBus
import Extensions
import Foundation
import Logging
import LoggingSetup
import Models
import PathLib
import PortDeterminer
import QueueClient
import QueueServer
import RemotePortDeterminer
import RemoteQueue
import RequestSender
import ResourceLocationResolver
import RuntimeDump
import SignalHandling
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff
import UniqueIdentifierGenerator
import Version

public final class RunTestsOnRemoteQueueCommand: Command {
    public let name = "runTestsOnRemoteQueue"
    public let description = "Starts queue server on remote machine if needed and runs tests on the remote queue. Waits for resuls to come back."
    public let arguments: Arguments = [
        ArgumentDescriptions.junit.asOptional,
        ArgumentDescriptions.queueServerDestination.asRequired,
        ArgumentDescriptions.queueServerRunConfigurationLocation.asRequired,
        ArgumentDescriptions.runId.asRequired,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.trace.asOptional
    ]
    
    private let developerDirLocator: DeveloperDirLocator
    private let localQueueVersionProvider: VersionProvider
    private let requestSenderProvider: RequestSenderProvider
    private let resourceLocationResolver: ResourceLocationResolver

    public init(
        developerDirLocator: DeveloperDirLocator,
        localQueueVersionProvider: VersionProvider,
        requestSenderProvider: RequestSenderProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.developerDirLocator = developerDirLocator
        self.localQueueVersionProvider = localQueueVersionProvider
        self.requestSenderProvider = requestSenderProvider
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func run(payload: CommandPayload) throws {
        let commonReportOutput = ReportOutput(
            junit: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.junit.name),
            tracingReport: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.trace.name)
        )
        let eventBus = EventBus()
        defer { eventBus.tearDown() }
        
        let queueServerDestination = try ArgumentsReader.deploymentDestinations(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerDestination.name)
        ).elementAtIndex(0, "first and single queue server destination")
        
        let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerRunConfigurationLocation.name)
        let runId: JobId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.runId.name)
        
        let tempFolder = try TemporaryFolder(containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name))
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        
        let runningQueueServerAddress = try detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
            queueServerDestination: queueServerDestination,
            queueServerRunConfigurationLocation: queueServerRunConfigurationLocation,
            runId: runId,
            tempFolder: tempFolder
        )
        let jobResults = try runTestsOnRemotelyRunningQueue(
            eventBus: eventBus,
            queueServerAddress: runningQueueServerAddress,
            runId: runId,
            tempFolder: tempFolder,
            testArgFile: testArgFile
        )
        let resultOutputGenerator = ResultingOutputGenerator(
            testingResults: jobResults.testingResults,
            commonReportOutput: commonReportOutput,
            testDestinationConfigurations: testArgFile.testDestinationConfigurations
        )
        try resultOutputGenerator.generateOutput()
    }
    
    private func detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
        queueServerDestination: DeploymentDestination,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        runId: JobId,
        tempFolder: TemporaryFolder
    ) throws -> SocketAddress {
        Logger.info("Searching for queue server on '\(queueServerDestination.host)'")
        let remoteQueueDetector = RemoteQueueDetector(
            localQueueClientVersionProvider: localQueueVersionProvider,
            remotePortDeterminer: RemoteQueuePortScanner(
                host: queueServerDestination.host,
                portRange: Ports.defaultQueuePortRange,
                requestSenderProvider: requestSenderProvider
            )
        )
        var suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10.0)
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
            deploymentId: runId.value,
            emceeVersionProvider: localQueueVersionProvider,
            deploymentDestination: queueServerDestination,
            queueServerRunConfigurationLocation: queueServerRunConfigurationLocation,
            tempFolder: tempFolder
        )
        try remoteQueueStarter.deployAndStart()
        
        try SynchronousWaiter.waitWhile(pollPeriod: 1.0, timeout: 30.0, description: "Wait for remote queue to start") {
            suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts(timeout: 10.0)
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
        eventBus: EventBus,
        queueServerAddress: SocketAddress,
        runId: JobId,
        tempFolder: TemporaryFolder,
        testArgFile: TestArgFile
    ) throws -> JobResults {
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            developerDirLocator: developerDirLocator,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        let runtimeTestQuerier = RuntimeTestQuerierImpl(
            eventBus: eventBus,
            developerDirLocator: developerDirLocator,
            numberOfAttemptsToPerformRuntimeDump: 5,
            onDemandSimulatorPool: onDemandSimulatorPool,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: DefaultTestRunnerProvider(resourceLocationResolver: resourceLocationResolver),
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator()
        )
        
        let queueClient = SynchronousQueueClient(queueServerAddress: queueServerAddress)
        
        defer {
            Logger.info("Will delete job \(runId)")
            do {
                _ = try queueClient.delete(jobId: runId)
            } catch {
                Logger.error("Failed to delete job \(runId): \(error)")
            }
        }

        let testEntriesValidator = TestEntriesValidator(
            testArgFileEntries: testArgFile.entries,
            runtimeTestQuerier: runtimeTestQuerier
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
                        jobId: runId,
                        priority: testArgFile.priority
                    ),
                    scheduleStrategy: testArgFileEntry.scheduleStrategy,
                    testEntryConfigurations: testEntryConfigurations,
                    requestId: RequestId(value: runId.value + "_" + UUID().uuidString)
                )
            } catch {
                Logger.error("Failed to schedule tests: \(error)")
                throw error
            }
        }
        
        var caughtSignal = false
        SignalHandling.addSignalHandler(signals: [.int, .term]) { signal in
            Logger.info("Caught \(signal) signal")
            Logger.info("Will delete job \(runId)")
            _ = try? queueClient.delete(jobId: runId)
            caughtSignal = true
        }
        
        Logger.info("Will now wait for job queue to deplete")
        try SynchronousWaiter.waitWhile(pollPeriod: 30.0, description: "Wait for job queue to deplete") {
            if caughtSignal { return false }
            let jobState = try queueClient.jobState(jobId: runId)
            switch jobState.queueState {
            case .deleted:
                return false
            case .running(let runningQueueState):
                BucketQueueStateLogger(runningQueueState: runningQueueState).logQueueSize()
                return !runningQueueState.isDepleted
            }
        }
        Logger.info("Will now fetch job results")
        return try queueClient.jobResults(jobId: runId)
    }
    
    private func selectPort(ports: Set<Int>) throws -> Int {
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
