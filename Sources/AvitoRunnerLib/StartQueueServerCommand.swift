import ArgumentsParser
import Extensions
import Foundation
import LocalQueueServerRunner
import Logging
import Models
import PluginManager
import PortDeterminer
import ResourceLocationResolver
import Utility
import Version

final class StartQueueServerCommand: Command {
    let command = "startLocalQueueServer"
    let overview = "Starts queue server on local machine. This mode waits for jobs to be scheduled via REST API."
    
    private let queueServerRunConfigurationLocation: OptionArgument<String>
    
    private let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
    private let resourceLocationResolver = ResourceLocationResolver()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        queueServerRunConfigurationLocation = subparser.add(stringArgument: KnownStringArguments.queueServerRunConfigurationLocation)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let queueServerRunConfiguration = try ArgumentsReader.queueServerRunConfiguration(
            arguments.get(self.queueServerRunConfigurationLocation),
            key: KnownStringArguments.queueServerRunConfigurationLocation,
            resourceLocationResolver: resourceLocationResolver
        )
        try startQueueServer(queueServerRunConfiguration: queueServerRunConfiguration)
    }
    
    private func startQueueServer(queueServerRunConfiguration: QueueServerRunConfiguration) throws {
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: queueServerRunConfiguration.auxiliaryResources.plugins,
            resourceLocationResolver: resourceLocationResolver,
            environment: [:]
        )
        defer { eventBus.tearDown() }
        
        let localQueueServerRunner = LocalQueueServerRunner(
            eventBus: eventBus,
            localPortDeterminer: LocalPortDeterminer(portRange: Ports.defaultQueuePortRange),
            localQueueVersionProvider: localQueueVersionProvider,
            queueServerRunConfiguration: queueServerRunConfiguration
        )
        try localQueueServerRunner.start()
    }
}
