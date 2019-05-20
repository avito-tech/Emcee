import EventBus
import Foundation
import Models
import ResourceLocationResolver
import RuntimeDump
import TempFolder
import SimulatorPool

public final class TestEntriesValidator {
    
    private let eventBus: EventBus
    private let runtimeDumpConfiguration: RuntimeDumpConfiguration
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TempFolder

    public init(
        eventBus: EventBus,
        runtimeDumpConfiguration: RuntimeDumpConfiguration,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TempFolder)
    {
        self.eventBus = eventBus
        self.runtimeDumpConfiguration = runtimeDumpConfiguration
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
    }
    
    public func validatedTestEntries() throws -> [TestToRun: [TestEntry]] {
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
        defer { onDemandSimulatorPool.deleteSimulators() }

        let runtimeQueryResult = try RuntimeTestQuerier(
            eventBus: eventBus,
            configuration: runtimeDumpConfiguration,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder)
            .queryRuntime()
        let transformer = TestToRunIntoTestEntryTransformer(testsToRun: runtimeDumpConfiguration.testsToRun)
        return try transformer.transform(runtimeQueryResult: runtimeQueryResult)
    }
}
