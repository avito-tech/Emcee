import BalancingBucketQueue
import CommonTestModels
import Dispatch
import Foundation
import EmceeLogging
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import SynchronousWaiter
import WorkerAlivenessModels
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
            configuredTestEntries: payload.similarlyConfiguredTestEntries.configuredTestEntries,
            testSplitter: payload.scheduleStrategy.testSplitter,
            prioritizedJob: payload.prioritizedJob
        )
        return .scheduledTests
    }
    
    private func waitForAnySuitableWorker(payload: ScheduleTestsPayload) throws {
        guard !payload.similarlyConfiguredTestEntries.testEntries.isEmpty else { return }
        
        let configurationHasAllRequirementsMet: () -> Bool = {
            self.workerAlivenessProvider.workerAliveness.contains(
                where: { (item: (workerId: WorkerId, aliveness: WorkerAliveness)) -> Bool in
                    guard item.aliveness.isInWorkingCondition else { return false }
                    return self.workerCapabilityConstraintResolver.requirementsSatisfied(
                        requirements: payload.similarlyConfiguredTestEntries.testEntryConfiguration.workerCapabilityRequirements,
                        workerCapabilities: self.workerCapabilitiesStorage.workerCapabilities(
                            forWorkerId: item.workerId
                        )
                    )
                }
            )
        }
        
        try SynchronousWaiter().mapErrorIfTimeout(
            work: { waiter in
                try waiter.waitWhile(
                    timeout: waitForCapableWorkerTimeout,
                    description: "Test entry configuration requirements can be satisfied"
                ) {
                    configurationHasAllRequirementsMet() == false
                }
            },
            timeoutToErrorTransformation: { timeout -> Error in
                NoSuitableWorkerAppearedError(
                    testEntryConfiguration: payload.similarlyConfiguredTestEntries.testEntryConfiguration,
                    timeout: timeout.value
                )
            }
        )
    }
}

private struct NoSuitableWorkerAppearedError: Error, CustomStringConvertible {
    let testEntryConfiguration: TestEntryConfiguration
    let timeout: TimeInterval
    
    var description: String {
        "Some worker requirements cannot be met after waiting for \(timeout.loggableInSeconds()) for any worker with suitable capabilities to appear: \(testEntryConfiguration)"
    }
}
