import ArgLib
import AutomaticTermination
import BucketQueue
import EmceeDI
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
import QueueServerConfiguration
import RESTServer
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
    
    private let di: DI
    private let httpRestServer: HTTPRESTServer
    
    public init(di: DI) throws {
        self.di = di
        self.httpRestServer = HTTPRESTServer(
            automaticTerminationController: StayAliveTerminationController(),
            logger: try di.get(),
            portProvider: AnyAvailablePortProvider(),
            useOnlyIPv4: false
        )
    }
    
    public func run(payload: CommandPayload) throws {
        let commonReportOutput = ReportOutput(
            junit: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.junit.name),
            tracingReport: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.trace.name)
        )
        
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        let logger = try di.get(ContextualLogger.self)

        let remoteCacheConfig = try ArgumentsReader.remoteCacheConfig(
            try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.remoteCacheConfig.name)
        )
        
        let tempFolder = try TemporaryFolder(containerPath: try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name))
        
        let queueServerConfiguration = try ArgumentsReader.queueServerConfiguration(
            location: try payload.expectedSingleTypedValue(
                argumentName: ArgumentDescriptions.queueServerConfigurationLocation.name
            ),
            resourceLocationResolver: try di.get()
        )
        let testArgFile = try ArgumentsReader.testArgFile(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name)
        )
        
        try RunTestsOnRemoteQueueLogic(di: di).run(
            commonReportOutput: commonReportOutput,
            emceeVersion: emceeVersion,
            logger: logger,
            queueServerConfiguration: queueServerConfiguration,
            remoteCacheConfig: remoteCacheConfig,
            tempFolder: tempFolder,
            testArgFile: testArgFile,
            httpRestServer: httpRestServer
        )
    }
}
