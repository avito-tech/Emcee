import DI
import Dispatch
import Foundation
import Logging
import Metrics
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
                    persistentMetricsJobId: testArgFile.prioritizedJob.persistentMetricsJobId,
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
            persistentMetricsJobId: testArgFile.prioritizedJob.persistentMetricsJobId
        )
        
        _ = try testEntriesValidator.validatedTestEntries { testArgFileEntry, validatedTestEntry in
            let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
                validatedEntries: validatedTestEntry,
                testArgFileEntry: testArgFileEntry,
                persistentMetricsJobId: testArgFile.prioritizedJob.persistentMetricsJobId
            )
            let testEntryConfigurations = testEntryConfigurationGenerator.createTestEntryConfigurations()
            Logger.info("Will schedule \(testEntryConfigurations.count) tests to queue server at \(queueServerAddress)")
            
            let testScheduler = TestSchedulerImpl(
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
        persistentMetricsJobId: String,
        queueHost: String,
        successful: Bool
    ) throws {
        try di.get(MetricRecorder.self).capture(
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