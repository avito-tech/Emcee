import EventBus
import Dispatch
import Foundation
import Logging
import Models
import ResourceLocationResolver
import RuntimeDump
import ScheduleStrategy
import TempFolder

/**
 * A data set for a Scheduler that splits the TestToRun into Buckets and provides them back to the Scheduler.
 * Useful for running tests locally, as the array of TestToRun is known.
 * Not very useful for distributed runs as you don't really know what Bucket the server will provide you back.
 */
public final class LocalRunSchedulerDataSource: SchedulerDataSource {
    private let configuration: LocalTestRunConfiguration
    private var buckets: [Bucket]
    private let syncQueue = DispatchQueue(label: "ru.avito.LocalRunSchedulerDataSource")

    public init(
        eventBus: EventBus,
        configuration: LocalTestRunConfiguration,
        runAllTestsIfTestsToRunIsEmpty: Bool,
        tempFolder: TempFolder,
        resourceLocationResolver: ResourceLocationResolver) throws
    {
        self.configuration = configuration
        self.buckets = try LocalRunSchedulerDataSource.prepareBuckets(
            eventBus: eventBus,
            configuration: configuration,
            runAllTestsIfTestsToRunIsEmpty: runAllTestsIfTestsToRunIsEmpty,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver)
    }
    
    public func nextBucket() -> Bucket? {
        return syncQueue.sync {
            return buckets.popLast()
        }
    }
    
    private static func prepareBuckets(
        eventBus: EventBus,
        configuration: LocalTestRunConfiguration,
        runAllTestsIfTestsToRunIsEmpty: Bool,
        tempFolder: TempFolder,
        resourceLocationResolver: ResourceLocationResolver)
        throws -> [Bucket]
    {
        let testEntries = try validatedTestEntries(
            eventBus: eventBus,
            configuration: configuration,
            runAllTestsIfTestsToRunIsEmpty: runAllTestsIfTestsToRunIsEmpty,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver)
        
        let strategy = configuration.testExecutionBehavior.scheduleStrategy.scheduleStrategy()
        let buckets = BucketsGenerator.generateBuckets(
            strategy: strategy,
            numberOfDestinations: configuration.testExecutionBehavior.numberOfSimulators,
            testEntries: testEntries,
            testDestinations: configuration.testDestinations,
            toolResources: configuration.auxiliaryResources.toolResources)

        log("Using strategy: \(strategy.description)")
        log("Will execute \(testEntries.count) tests: \(testEntries)")
        log("Will split tests into following buckets:")
        buckets.forEach { log("Bucket: \($0)") }
        return buckets
    }
    
    private static func validatedTestEntries(
        eventBus: EventBus,
        configuration: LocalTestRunConfiguration,
        runAllTestsIfTestsToRunIsEmpty: Bool,
        tempFolder: TempFolder,
        resourceLocationResolver: ResourceLocationResolver)
        throws -> [TestEntry]
    {
        let transformer = TestToRunIntoTestEntryTransformer(
            eventBus: eventBus,
            configuration: RuntimeDumpConfiguration.fromLocalRunTestConfiguration(configuration),
            fetchAllTestsIfTestsToRunIsEmpty: runAllTestsIfTestsToRunIsEmpty,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver)
        let testEntries = try transformer.transform().avito_shuffled()
        if testEntries.isEmpty {
            log("No tests found.")
            return []
        }
        return Array(testEntries.reversed())
    }
}
