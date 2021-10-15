import ArgLib
import AtomicModels
import BuildArtifacts
import ChromeTracing
import DateProvider
import DeveloperDirLocator
import DI
import EmceeVersion
import FileSystem
import Foundation
import EmceeLogging
import LoggingSetup
import Metrics
import MetricsExtensions
import PathLib
import PluginManager
import ProcessController
import QueueModels
import ResourceLocation
import ResourceLocationResolver
import RunnerModels
import ScheduleStrategy
import Scheduler
import SignalHandling
import SimulatorPool
import Tmp
import TestDiscovery
import URLResource
import UniqueIdentifierGenerator

public final class DumpCommand: Command {
    public let name = "dump"
    public let description = "Performs test discovery and dumps information about discovered tests into JSON file"
    public let arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asOptional,
        ArgumentDescriptions.output.asRequired,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.remoteCacheConfig.asOptional,
    ]
    
    private let di: DI
    private let encoder = JSONEncoder.pretty()
    
    public init(di: DI) throws {
        self.di = di
    }

    public func run(payload: CommandPayload) throws {
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        let remoteCacheConfig = try ArgumentsReader.remoteCacheConfig(
            try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.remoteCacheConfig.name)
        )
        let tempFolder = try TemporaryFolder(
            containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name)
        )
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version

        di.set(tempFolder, for: TemporaryFolder.self)
        
        try di.get(GlobalMetricRecorder.self).set(analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration)
        if let kibanaConfiguration = testArgFile.prioritizedJob.analyticsConfiguration.kibanaConfiguration {
            try di.get(LoggingSetup.self).set(kibanaConfiguration: kibanaConfiguration)
        }
        di.set(
            try di.get(ContextualLogger.self).with(
                analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration
            )
        )
        
        let logger = try di.get(ContextualLogger.self)
        
        let onDemandSimulatorPool = try OnDemandSimulatorPoolFactory.create(
            di: di,
            logger: logger,
            version: emceeVersion
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        di.set(onDemandSimulatorPool, for: OnDemandSimulatorPool.self)
        
        SignalHandling.addSignalHandler(signals: [.term, .int]) { [logger] signal in
            logger.debug("Got signal: \(signal)")
            onDemandSimulatorPool.deleteSimulators()
        }
        
        let discoverer = PipelinedTestDiscoverer(
            runtimeDumpRemoteCacheProvider: try di.get(),
            testDiscoveryQuerier: try di.get(),
            urlResource: try di.get()
        )
        
        let dumpedTests = try discoverer.performTestDiscovery(
            logger: logger,
            testArgFile: testArgFile,
            remoteCacheConfig: remoteCacheConfig
        )
        
        do {
            let encodedResult = try encoder.encode(dumpedTests)
            try encodedResult.write(to: outputPath.fileUrl, options: [.atomic])
            logger.debug("Wrote run time tests dump to file \(outputPath)")
        } catch {
            logger.error("Failed to write output: \(error)")
        }
    }
}
