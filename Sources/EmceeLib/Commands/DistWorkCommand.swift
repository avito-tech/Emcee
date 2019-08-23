import ArgLib
import DistWorker
import Foundation
import Logging
import LoggingSetup
import Models
import PathLib
import ResourceLocationResolver
import TemporaryStuff
import Utility

public final class DistWorkCommand: Command {
    public let name = "distWork"
    public let description = "Takes jobs from a dist runner queue and performs them"
    public var arguments: Arguments = [
        ArgumentDescriptions.analyticsConfiguration.asOptional,
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired
    ]
    
    private let resourceLocationResolver = ResourceLocationResolver()
    
    public func run(payload: CommandPayload) throws {
        let analyticsConfigurationLocation: AnalyticsConfigurationLocation? = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.analyticsConfiguration.name)
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)

        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            try AnalyticsConfigurator(resourceLocationResolver: resourceLocationResolver)
                .setup(analyticsConfigurationLocation: analyticsConfigurationLocation)
        }

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
            temporaryFolder: temporaryFolder,
            testRunnerProvider: DefaultTestRunnerProvider(
                resourceLocationResolver: resourceLocationResolver
            )
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
