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

    public init(configuration: LocalTestRunConfiguration) {
        self.configuration = configuration
        self.buckets = LocalRunSchedulerDataSource.prepareBuckets(configuration: configuration)
    }
    
    public func nextBucket() -> SchedulerBucket? {
        return syncQueue.sync {
            if let bucket = buckets.popLast() {
                return SchedulerBucket.from(bucket: bucket)
            } else {
                return nil
            }
        }
    }
    
    private static func prepareBuckets(configuration: LocalTestRunConfiguration) -> [Bucket] {
        let splitter = configuration.testRunExecutionBehavior.scheduleStrategy.bucketSplitter()
        log("Using strategy: \(splitter.description)")
        
        let buckets = splitter.generate(
            inputs: configuration.testEntryConfigurations,
            splitInfo: BucketSplitInfo(
                numberOfWorkers: configuration.testRunExecutionBehavior.numberOfSimulators,
                toolResources: configuration.auxiliaryResources.toolResources,
                simulatorSettings: configuration.simulatorSettings
            )
        )

        log("Will execute \(configuration.testEntryConfigurations.count) tests: \(configuration.testEntryConfigurations)")
        log("Will split tests into following buckets:")
        buckets.forEach { log("Bucket: \($0)") }
        return buckets
    }
}
