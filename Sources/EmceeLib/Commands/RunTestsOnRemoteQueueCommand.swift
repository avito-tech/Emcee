import ArgumentsParser
import BucketQueue
import DistDeployer
import EventBus
import Extensions
import Foundation
import Logging
import LoggingSetup
import Models
import PortDeterminer
import QueueClient
import QueueServer
import PathLib
import RemotePortDeterminer
import RemoteQueue
import ResourceLocationResolver
import SignalHandling
import SynchronousWaiter
import TemporaryStuff
import Utility
import Version
import SimulatorPool
import RuntimeDump

final class RunTestsOnRemoteQueueCommand: Command {
    let command = "runTestsOnRemoteQueue"
    let overview = "Starts queue server on remote machine if needed and runs tests on the remote queue. Waits for resuls to come back."

    private let analyticsConfigurationLocation: OptionArgument<String>
    private let workerDestinations: OptionArgument<String>
    private let fbsimctl: OptionArgument<String>
    private let fbxctest: OptionArgument<String>
    private let junit: OptionArgument<String>
    private let priority: OptionArgument<UInt>
    private let plugins: OptionArgument<[String]>
    private let queueServerDestination: OptionArgument<String>
    private let queueServerRunConfigurationLocation: OptionArgument<String>
    private let runId: OptionArgument<String>
    private let testArgFile: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let trace: OptionArgument<String>
    private let tempFolder: OptionArgument<String>

    
    private let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
    private let resourceLocationResolver = ResourceLocationResolver()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)

        analyticsConfigurationLocation = subparser.add(stringArgument: KnownStringArguments.analyticsConfiguration)
        fbsimctl = subparser.add(stringArgument: KnownStringArguments.fbsimctl)
        fbxctest = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        junit = subparser.add(stringArgument: KnownStringArguments.junit)
        priority = subparser.add(intArgument: KnownUIntArguments.priority)
        plugins = subparser.add(multipleStringArgument: KnownStringArguments.plugin)
        queueServerDestination = subparser.add(stringArgument: KnownStringArguments.queueServerDestination)
        queueServerRunConfigurationLocation = subparser.add(stringArgument: KnownStringArguments.queueServerRunConfigurationLocation)
        runId = subparser.add(stringArgument: KnownStringArguments.runId)
        testArgFile = subparser.add(stringArgument: KnownStringArguments.testArgFile)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        trace = subparser.add(stringArgument: KnownStringArguments.trace)
        workerDestinations = subparser.add(stringArgument: KnownStringArguments.destinations)
        tempFolder = subparser.add(stringArgument: KnownStringArguments.tempFolder)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let analyticsConfigurationLocation = AnalyticsConfigurationLocation(
            try ArgumentsReader.validateResourceLocationOrNil(arguments.get(self.analyticsConfigurationLocation), key: KnownStringArguments.analyticsConfiguration)
        )
        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            try AnalyticsConfigurator(resourceLocationResolver: resourceLocationResolver)
                .setup(analyticsConfigurationLocation: analyticsConfigurationLocation)
        }
        let commonReportOutput = ReportOutput(
            junit: arguments.get(self.junit),
            tracingReport: arguments.get(self.trace)
        )
        let eventBus = EventBus()
        defer { eventBus.tearDown() }
        
        let testRunnerTool = TestRunnerTool.fbxctest(
            FbxctestLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest))
        )
        let simulatorControlTool = (try? ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl)).map {
            SimulatorControlTool.fbsimctl(FbsimctlLocation($0))
        }
        let priority = try Priority(intValue: try ArgumentsReader.validateNotNil(arguments.get(self.priority), key: KnownUIntArguments.priority))
        let pluginLocations = try ArgumentsReader.validateResourceLocations(arguments.get(self.plugins) ?? [], key: KnownStringArguments.plugin).map({ PluginLocation($0) })
        
        let queueServerDestination = try ArgumentsReader.deploymentDestinations(
            arguments.get(self.queueServerDestination),
            key: KnownStringArguments.queueServerDestination
        ).elementAtIndex(0, "first and single queue server destination")
        let queueServerRunConfigurationLocation = QueueServerRunConfigurationLocation(
            try ArgumentsReader.validateResourceLocation(
                arguments.get(self.queueServerRunConfigurationLocation),
                key: KnownStringArguments.queueServerRunConfigurationLocation
            )
        )
        let runId = JobId(value: try ArgumentsReader.validateNotNil(arguments.get(self.runId), key: KnownStringArguments.runId))
        let tempFolder = try TemporaryFolder(
            containerPath: AbsolutePath(
                try ArgumentsReader.validateNotNil(
                    arguments.get(self.tempFolder), key: KnownStringArguments.tempFolder
                )
            )
        )
        let testArgFile = try ArgumentsReader.testArgFile(arguments.get(self.testArgFile), key: KnownStringArguments.testArgFile)
        let testDestinationConfigurations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)
        let workerDestinations = try ArgumentsReader.deploymentDestinations(arguments.get(self.workerDestinations), key: KnownStringArguments.destinations)
        
        let runningQueueServerAddress = try detectRemotelyRunningQueueServerPortsOrStartRemoteQueueIfNeeded(
            analyticsConfigurationLocation: analyticsConfigurationLocation,
            pluginLocations: pluginLocations,
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
        pluginLocations: [PluginLocation],
        queueServerDestination: DeploymentDestination,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        runId: JobId,
        tempFolder: TemporaryFolder,
        workerDestinations: [DeploymentDestination])
        throws -> SocketAddress
    {
        Logger.info("Searching for queue server on '\(queueServerDestination.host)'")
        let remoteQueueDetector = RemoteQueueDetector(
            localQueueClientVersionProvider: localQueueVersionProvider,
            remotePortDeterminer: RemoteQueuePortScanner(
                host: queueServerDestination.host,
                portRange: Ports.defaultQueuePortRange
            )
        )
        var suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts()
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
        
        try SynchronousWaiter.waitWhile(pollPeriod: 1.0, timeout: 10.0, description: "Wait for remote queue to start") {
            suitablePorts = try remoteQueueDetector.findSuitableRemoteRunningQueuePorts()
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
            pluginLocations: pluginLocations,
            queueAddress: queueServerAddress,
            analyticsConfigurationLocation: analyticsConfigurationLocation,
            tempFolder: tempFolder
        )
        try remoteWorkersStarter.deployAndStartWorkers()
        
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
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder
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
