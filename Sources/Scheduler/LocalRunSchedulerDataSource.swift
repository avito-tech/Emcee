import Dispatch
import Foundation
import Logging
import Models
import RuntimeDump
import ScheduleStrategy

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
        configuration: LocalTestRunConfiguration,
        runAllTestsIfTestsToRunIsEmpty: Bool) throws
    {
        self.configuration = configuration
        self.buckets = try LocalRunSchedulerDataSource.prepareBuckets(
            configuration: configuration,
            runAllTestsIfTestsToRunIsEmpty: runAllTestsIfTestsToRunIsEmpty)
    }
    
    public func nextBucket() -> Bucket? {
        return syncQueue.sync {
            return buckets.popLast()
        }
    }
    
    private static func prepareBuckets(
        configuration: LocalTestRunConfiguration,
        runAllTestsIfTestsToRunIsEmpty: Bool)
        throws -> [Bucket]
    {
        let testEntries = try validatedTestEntries(
            configuration: configuration,
            runAllTestsIfTestsToRunIsEmpty: runAllTestsIfTestsToRunIsEmpty)
        
        let strategy = configuration.testExecutionBehavior.scheduleStrategy.scheduleStrategy()
        let buckets = BucketsGenerator.generateBuckets(
            strategy: strategy,
            numberOfDestinations: configuration.testExecutionBehavior.numberOfSimulators,
            testEntries: testEntries,
            testDestinations: configuration.testDestinations)

        log("Using strategy: \(strategy.description)")
        log("Will execute \(testEntries.count) tests: \(testEntries)")
        log("Will split tests into following buckets:")
        buckets.forEach { log("Bucket: \($0)") }
        return buckets
    }
    
    private static func validatedTestEntries(
        configuration: LocalTestRunConfiguration,
        runAllTestsIfTestsToRunIsEmpty: Bool)
        throws -> [TestEntry]
    {
        let transformer = TestToRunIntoTestEntryTransformer(
            configuration: RuntimeDumpConfiguration.fromLocalRunTestConfiguration(configuration),
            fetchAllTestsIfTestsToRunIsEmpty: runAllTestsIfTestsToRunIsEmpty)
        let testEntries = try transformer.transform().avito_shuffled()
        if testEntries.isEmpty {
            log("No tests found.")
            return []
        }
        return Array(testEntries.reversed())
    }
}
