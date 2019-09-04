import ArgLib
import BucketQueue
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
import Version

public final class RunTestsOnRemoteQueueCommand: Command {
    public let name = "runTestsOnRemoteQueue"
    public let description = "Starts queue server on remote machine if needed and runs tests on the remote queue. Waits for resuls to come back."
    public let arguments: Arguments = [
        ArgumentDescriptions.analyticsConfiguration.asOptional,
        ArgumentDescriptions.fbsimctl.asRequired,
        ArgumentDescriptions.fbxctest.asRequired,
        ArgumentDescriptions.junit.asOptional,
        ArgumentDescriptions.plugin.asOptional,
        ArgumentDescriptions.priority.asRequired,
        ArgumentDescriptions.queueServerDestination.asRequired,
        ArgumentDescriptions.queueServerRunConfigurationLocation.asRequired,
        ArgumentDescriptions.runId.asRequired,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.testDestinations.asRequired,
        ArgumentDescriptions.trace.asOptional,
        ArgumentDescriptions.workerDestinations.asRequired,
    ]
    
    private let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func run(payload: CommandPayload) throws {
        let analyticsConfigurationLocation: AnalyticsConfigurationLocation? = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.analyticsConfiguration.name)
        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            try AnalyticsConfigurator(resourceLocationResolver: resourceLocationResolver).setup(analyticsConfigurationLocation: analyticsConfigurationLocation)
        }
        
        let commonReportOutput = ReportOutput(
            junit: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.junit.name),
            tracingReport: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.trace.name)
        )
        let eventBus = EventBus()
        defer { eventBus.tearDown() }
        
        let testRunnerTool: TestRunnerTool = .fbxctest(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.fbxctest.name)
        )
        
        let simulatorControlTool: SimulatorControlTool = SimulatorControlTool.fbsimctl(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.fbsimctl.name)
        )

        let priority: Priority = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.priority.name)
        
        let queueServerDestination = try ArgumentsReader.deploymentDestinations(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerDestination.name)
        ).elementAtIndex(0, "first and single queue server destination")
        
        let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerRunConfigurationLocation.name)
        let runId: JobId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.runId.name)
        
        let tempFolder = try TemporaryFolder(containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name))
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        
        let testDestinationConfigurations = try ArgumentsReader.testDestinations(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testDestinations.name))
        let workerDestinations = try ArgumentsReader.deploymentDestinations(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerDestinations.name))
        
        let runningQueueServerAddress = try detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
            analyticsConfigurationLocation: analyticsConfigurationLocation,
            queueServerDestination: queueServerDestination,
            queueServerRunConfigurationLocation: queueServerRunConfigurationLocation,
            runId: runId,
            tempFolder: tempFolder,
            workerDestinations: workerDestinations
        )
        let jobResults = try runTestsOnRemotelyRunningQueue(
            eventBus: eventBus,
            testRunnerTool: testRunnerTool,
            simulatorControlTool: simulatorControlTool,
            priority: priority,
            queueServerAddress: runningQueueServerAddress,
            runId: runId,
            tempFolder: tempFolder,
            testArgFile: testArgFile,
            testDestinationConfigurations: testDestinationConfigurations
        )
        let resultOutputGenerator = ResultingOutputGenerator(
            testingResults: jobResults.testingResults,
            commonReportOutput: commonReportOutput,
            testDestinationConfigurations: testDestinationConfigurations
        )
        try resultOutputGenerator.generateOutput()
    }
    
    private func detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
        analyticsConfigurationLocation: AnalyticsConfigurationLocation?,
        queueServerDestination: DeploymentDestination,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        runId: JobId,
        tempFolder: TemporaryFolder,
        workerDestinations: [DeploymentDestination]
    ) throws -> SocketAddress {
        Logger.info("Searching for queue server on '\(queueServerDestination.host)'")
        let remoteQueueDetector = RemoteQueueDetector(
            localQueueClientVersionProvider: localQueueVersionProvider,
            remotePortDeterminer: RemoteQueuePortScanner(
                host: queueServerDestination.host,
                portRange: Ports.defaultQueuePortRange,
                requestSenderProvider: DefaultRequestSenderProvider()
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
        
        Logger.info("Deploying and starting workers")
        let remoteWorkersStarter = RemoteWorkersStarter(
            deploymentId: runId.value,
            emceeVersionProvider: localQueueVersionProvider,
            deploymentDestinations: workerDestinations,
            analyticsConfigurationLocation: analyticsConfigurationLocation,
            tempFolder: tempFolder
        )
        try remoteWorkersStarter.deployAndStartWorkers(
            queueAddress: queueServerAddress
        )
        
        return queueServerAddress
    }
    
    private func runTestsOnRemotelyRunningQueue(
        eventBus: EventBus,
        testRunnerTool: TestRunnerTool,
        simulatorControlTool: SimulatorControlTool?,
        priority: Priority,
        queueServerAddress: SocketAddress,
        runId: JobId,
        tempFolder: TemporaryFolder,
        testArgFile: TestArgFile,
        testDestinationConfigurations: [TestDestinationConfiguration]
    ) throws -> JobResults {
        let validatorConfiguration = TestEntriesValidatorConfiguration(
            simulatorControlTool: simulatorControlTool,
            testDestination: testDestinationConfigurations.elementAtIndex(0, "First test destination").testDestination,
            testEntries: testArgFile.entries,
            testRunnerTool: testRunnerTool
        )
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        let runtimeTestQuerier = RuntimeTestQuerierImpl(
            eventBus: eventBus,
            numberOfAttemptsToPerformRuntimeDump: 5,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder,
            testRunnerProvider: DefaultTestRunnerProvider(
                resourceLocationResolver: resourceLocationResolver
            )
        )

        let testEntriesValidator = TestEntriesValidator(
            validatorConfiguration: validatorConfiguration,
            runtimeTestQuerier: runtimeTestQuerier
        )
        let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
            validatedEntries: try testEntriesValidator.validatedTestEntries(),
            testArgEntries: testArgFile.entries
        )
        let testEntryConfigurations = testEntryConfigurationGenerator.createTestEntryConfigurations()
        Logger.info("Will schedule \(testEntryConfigurations.count) tests to queue server at \(queueServerAddress)")
        
        let queueClient = SynchronousQueueClient(queueServerAddress: queueServerAddress)
        _ = try queueClient.scheduleTests(
            prioritizedJob: PrioritizedJob(jobId: runId, priority: priority),
            scheduleStrategy: testArgFile.scheduleStrategy,
            testEntryConfigurations: testEntryConfigurations,
            requestId: RequestId(value: runId.value + "_" + UUID().uuidString)
        )
        
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
        let results = try queueClient.jobResults(jobId: runId)
        
        Logger.info("Will delete job \(runId)")
        _ = try queueClient.delete(jobId: runId)
        
        return results
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
