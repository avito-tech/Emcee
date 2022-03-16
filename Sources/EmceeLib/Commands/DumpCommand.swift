import ArgLib
import EmceeDI
import EmceeLogging
import EmceeVersion
import Foundation
import LocalHostDeterminer
import MetricsExtensions
import PathLib
import QueueModels
import SignalHandling
import SimulatorPool
import Tmp
import TestDiscovery

public final class DumpCommand: Command {
    public let name = "dump"
    public let description = "Performs test discovery and dumps information about discovered tests into JSON file"
    public let arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asOptional,
        ArgumentDescriptions.output.asRequired,
        ArgumentDescriptions.tempFolder.asRequired,
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.remoteCacheConfig.asOptional,
        ArgumentDescriptions.hostname.asOptional,
    ]
    
    private let di: DI
    private let encoder = JSONEncoder.pretty()
    
    public init(di: DI) throws {
        self.di = di
    }

    public func run(payload: CommandPayload) throws {
        let hostname: String = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.hostname.name) ?? LocalHostDeterminer.currentHostAddress
        try HostnameSetup.update(hostname: hostname, di: di)
    
        let testArgFile = try ArgumentsReader.testArgFile(try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name))
        let remoteCacheConfig = try ArgumentsReader.remoteCacheConfig(
            try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.remoteCacheConfig.name)
        )
        let tempFolder = try TemporaryFolder(
            containerPath: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.tempFolder.name)
        )
        let outputPath: AbsolutePath = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.output.name)
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        
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
            hostname: hostname,
            logger: logger,
            tempFolder: tempFolder,
            version: emceeVersion
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        di.set(onDemandSimulatorPool, for: OnDemandSimulatorPool.self)
        
        SignalHandling.addSignalHandler(signals: [.term, .int]) { [logger] signal in
            logger.trace("Got signal: \(signal)")
            onDemandSimulatorPool.deleteSimulators()
        }
        
        di.set(
            TestDiscoveryQuerierImpl(
                dateProvider: try di.get(),
                developerDirLocator: try di.get(),
                fileSystem: try di.get(),
                hostname: hostname,
                globalMetricRecorder: try di.get(),
                specificMetricRecorderProvider: try di.get(),
                onDemandSimulatorPool: try di.get(),
                pluginEventBusProvider: try di.get(),
                processControllerProvider: try di.get(),
                resourceLocationResolver: try di.get(),
                runnerWasteCollectorProvider: try di.get(),
                tempFolder: tempFolder,
                testRunnerProvider: try di.get(),
                uniqueIdentifierGenerator: try di.get(),
                version: emceeVersion,
                waiter: try di.get()
            ),
            for: TestDiscoveryQuerier.self
        )
        
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
            logger.info("Wrote test discovery result into \(outputPath)")
        } catch {
            logger.error("Failed to write output: \(error)")
        }
    }
}
