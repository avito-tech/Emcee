import BalancingBucketQueue
import Dispatch
import Foundation
import Logging
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import SynchronousWaiter
import WorkerAlivenessProvider
import WorkerCapabilities
import UniqueIdentifierGenerator

public final class ScheduleTestsEndpoint: RESTEndpoint {
    private let testsEnqueuer: TestsEnqueuer
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let waitForCapableWorkerTimeout: TimeInterval
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerCapabilityConstraintResolver = WorkerCapabilityConstraintResolver()
    private let workerCapabilitiesStorage: WorkerCapabilitiesStorage
    public let path: RESTPath = RESTMethod.scheduleTests
    public let requestIndicatesActivity = true
    
    public init(
        testsEnqueuer: TestsEnqueuer,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        waitForCapableWorkerTimeout: TimeInterval,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage
    ) {
        self.testsEnqueuer = testsEnqueuer
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.waitForCapableWorkerTimeout = waitForCapableWorkerTimeout
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerCapabilitiesStorage = workerCapabilitiesStorage
    }
    
    public func handle(payload: ScheduleTestsPayload) throws -> ScheduleTestsResponse {
        try waitForAnySuitableWorker(payload: payload)
        
        try testsEnqueuer.enqueue(
            bucketSplitter: payload.scheduleStrategy.bucketSplitter(
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            ),
            testEntryConfigurations: payload.testEntryConfigurations,
            prioritizedJob: payload.prioritizedJob
        )
        return .scheduledTests
    }
    
    private func waitForAnySuitableWorker(payload: ScheduleTestsPayload) throws {
        do {
            try SynchronousWaiter().waitWhile(
                timeout: waitForCapableWorkerTimeout,
                description: "Any worker capable of executing tests"
            ) {
                for (workerId, workerAliveness) in workerAlivenessProvider.workerAliveness {
                    guard workerAliveness.isInWorkingCondition else { continue }
                    let workerCapabilities = workerCapabilitiesStorage.workerCapabilities(
                        forWorkerId: workerId
                    )
                    
                    for testEntryConfiguration in payload.testEntryConfigurations {
                        if workerCapabilityConstraintResolver.requirementsSatisfied(
                            requirements: testEntryConfiguration.workerCapabilityRequirements,
                            workerCapabilities: workerCapabilities
                        ) {
                            return false
                        }
                    }
                }
                return true
            }
        } catch {
            Logger.error("Can't execute tests from payload: no workers meeting requirements")
            throw error
        }
    }
}
