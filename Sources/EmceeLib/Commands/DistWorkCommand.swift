import ArgumentsParser
import DistWorker
import Foundation
import Logging
import LoggingSetup
import Models
import PathLib
import ResourceLocationResolver
import TemporaryStuff
import Utility

final class DistWorkCommand: Command {
    let command = "distWork"
    let overview = "Takes jobs from a dist runner queue and performs them"
    
    private let analyticsConfigurationLocation: OptionArgument<String>
    private let queueServer: OptionArgument<String>
    private let workerId: OptionArgument<String>
    private let resourceLocationResolver = ResourceLocationResolver()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        analyticsConfigurationLocation = subparser.add(stringArgument: KnownStringArguments.analyticsConfiguration)
        queueServer = subparser.add(stringArgument: KnownStringArguments.queueServer)
        workerId = subparser.add(stringArgument: KnownStringArguments.workerId)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let analyticsConfigurationLocation = AnalyticsConfigurationLocation(
            try ArgumentsReader.validateResourceLocationOrNil(arguments.get(self.analyticsConfigurationLocation), key: KnownStringArguments.analyticsConfiguration)
        )
        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            try AnalyticsConfigurator(resourceLocationResolver: resourceLocationResolver)
                .setup(analyticsConfigurationLocation: analyticsConfigurationLocation)
        }
        
        let queueServerAddress = try ArgumentsReader.socketAddress(arguments.get(self.queueServer), key: KnownStringArguments.queueServer)
        let workerId = WorkerId(
            value: try ArgumentsReader.validateNotNil(
                arguments.get(self.workerId), key: KnownStringArguments.workerId
            )
        )
        let temporaryFolder = try createScopedTemporaryFolder()

        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: temporaryFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let distWorker = DistWorker(
            onDemandSimulatorPool: onDemandSimulatorPool,
            queueServerAddress: queueServerAddress,
            workerId: workerId,
            resourceLocationResolver: resourceLocationResolver,
            temporaryFolder: temporaryFolder
        )
        try distWorker.start()
    }

    private func createScopedTemporaryFolder() throws -> TemporaryFolder {
        let containerPath = AbsolutePath(ProcessInfo.processInfo.executablePath)
            .removingLastComponent
            .appending(component: "tempFolder")
        return try TemporaryFolder(containerPath: containerPath)
    }
}
