import DI
import Dispatch
import Foundation
import EmceeLogging
import Metrics
import MetricsExtensions
import QueueClient
import QueueModels
import RequestSender
import SocketModels
import SynchronousWaiter
import TestArgFile
import TestDiscovery
import Types

public final class JobPreparer {
    private let di: DI
    private let callbackQueue = DispatchQueue(label: "JobPreparer.callbackQueue")
    
    public init(di: DI) {
        self.di = di
    }
    
    public func formJob(
        emceeVersion: Version,
        queueServerAddress: SocketAddress,
        remoteCacheConfig: RuntimeDumpRemoteCacheConfig?,
        testArgFile: TestArgFile
    ) throws {
        try TimeMeasurerImpl(dateProvider: try di.get()).measure(
            work: {
                try validateTestArgFileAndPrepareJob(
                    queueServerAddress: queueServerAddress,
                    remoteCacheConfig: remoteCacheConfig,
                    testArgFile: testArgFile
                )
            },
            result: { error, duration in
                try? reportJobPreparationDuration(
                    duration: duration,
                    emceeVersion: emceeVersion,
                    analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration,
                    queueHost: queueServerAddress.host,
                    successful: error == nil
                )
            }
        )
    }
    
    private func validateTestArgFileAndPrepareJob(
        queueServerAddress: SocketAddress,
        remoteCacheConfig: RuntimeDumpRemoteCacheConfig?,
        testArgFile: TestArgFile
    ) throws {
        let testEntriesValidator = TestEntriesValidator(
            remoteCache: try di.get(RuntimeDumpRemoteCacheProvider.self).remoteCache(config: remoteCacheConfig),
            testArgFileEntries: testArgFile.entries,
            testDiscoveryQuerier: try di.get(),
            analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration
        )
        
        let logger = try di.get(ContextualLogger.self)

        _ = try testEntriesValidator.validatedTestEntries(logger: logger) { testArgFileEntry, validatedTestEntry in
            let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
                analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration,
                validatedEntries: validatedTestEntry,
                testArgFileEntry: testArgFileEntry,
                logger: logger
            )
            let testEntryConfigurations = testEntryConfigurationGenerator.createTestEntryConfigurations()
            logger.info("Will schedule \(testEntryConfigurations.count) tests to queue server at \(queueServerAddress)")
            
            let testScheduler = TestSchedulerImpl(
                logger: logger,
                requestSender: try di.get(RequestSenderProvider.self).requestSender(socketAddress: queueServerAddress)
            )
            
            let callbackWaiter: CallbackWaiter<Either<Void, Error>> = try di.get(Waiter.self).createCallbackWaiter()
            testScheduler.scheduleTests(
                prioritizedJob: testArgFile.prioritizedJob,
                scheduleStrategy: testArgFileEntry.scheduleStrategy,
                testEntryConfigurations: testEntryConfigurations,
                callbackQueue: callbackQueue,
                completion: callbackWaiter.set
            )
            try callbackWaiter.wait(timeout: 60, description: "Schedule tests").dematerialize()
        }
    }
    
    private func reportJobPreparationDuration(
        duration: TimeInterval,
        emceeVersion: Version,
        analyticsConfiguration: AnalyticsConfiguration,
        queueHost: String,
        successful: Bool
    ) throws {
        if let persistentMetricsJobId = analyticsConfiguration.persistentMetricsJobId {
            try di.get(SpecificMetricRecorderProvider.self).specificMetricRecorder(
                analyticsConfiguration: analyticsConfiguration
            ).capture(
                JobPreparationDurationMetric(
                    queueHost: queueHost,
                    version: emceeVersion,
                    persistentMetricsJobId: persistentMetricsJobId,
                    successful: successful,
                    duration: duration
                )
            )
        }
    }
}
