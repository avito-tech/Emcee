import EventBus
import Foundation
import Models
import ResourceLocationResolver
import RuntimeDump
import TempFolder

public final class TestEntriesGenerator {
    
    private let eventBus: EventBus
    private let fetchAllTestsIfTestsToRunIsEmpty: Bool
    private let runtimeDumpConfiguration: RuntimeDumpConfiguration
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TempFolder

    public init(
        eventBus: EventBus,
        fetchAllTestsIfTestsToRunIsEmpty: Bool,
        runtimeDumpConfiguration: RuntimeDumpConfiguration,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TempFolder)
    {
        self.eventBus = eventBus
        self.fetchAllTestsIfTestsToRunIsEmpty = fetchAllTestsIfTestsToRunIsEmpty
        self.runtimeDumpConfiguration = runtimeDumpConfiguration
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
    }
    
    public func validatedTestEntries() throws -> [TestEntry] {
        let runtimeQueryResult = try RuntimeTestQuerier(
            eventBus: eventBus,
            configuration: runtimeDumpConfiguration,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
            .queryRuntime()
        let transformer = TestToRunIntoTestEntryTransformer(
            testsToRun: runtimeDumpConfiguration.testsToRun,
            fetchAllTestsIfTestsToRunIsEmpty: fetchAllTestsIfTestsToRunIsEmpty)
        let entries = try transformer.transform(runtimeQueryResult: runtimeQueryResult).flatMap { $1 }
        return entries.avito_shuffled()
    }
}
