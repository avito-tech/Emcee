import BalancingBucketQueue
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
            testEntryConfigurations: payload.testEntryConfigurations,
            testSplitter: payload.scheduleStrategy.testSplitter,
            prioritizedJob: payload.prioritizedJob
        )
        return .scheduledTests
    }
    
    private func waitForAnySuitableWorker(payload: ScheduleTestsPayload) throws {
        guard !payload.testEntryConfigurations.isEmpty else { return }
        
        let testEntryConfigurationsWithUnmetRequirements = {
            payload.testEntryConfigurations.filter { testEntryConfiguration -> Bool in
                let workersThatMeetRequirements = self.workerAlivenessProvider.workerAliveness.filter { (item: (workerId: WorkerId, aliveness: WorkerAliveness)) -> Bool in
                    guard item.aliveness.isInWorkingCondition else { return false }
                    return self.workerCapabilityConstraintResolver.requirementsSatisfied(
                        requirements: testEntryConfiguration.workerCapabilityRequirements,
                        workerCapabilities: self.workerCapabilitiesStorage.workerCapabilities(
                            forWorkerId: item.workerId
                        )
                    )
                }
                return workersThatMeetRequirements.isEmpty
            }
        }
        
        try SynchronousWaiter().mapErrorIfTimeout(
            work: { waiter in
                try waiter.waitWhile(
                    timeout: waitForCapableWorkerTimeout,
                    description: "All test entry configuration requirements can be satisfied"
                ) {
                    !testEntryConfigurationsWithUnmetRequirements().isEmpty
                }
            },
            timeoutToErrorTransformation: { timeout -> Error in
                NoSuitableWorkerAppearedError(
                    testEntryConfigurationsWithUnmetRequirements: testEntryConfigurationsWithUnmetRequirements(),
                    timeout: timeout.value
                )
            }
        )
    }
}

private struct NoSuitableWorkerAppearedError: Error, CustomStringConvertible {
    let testEntryConfigurationsWithUnmetRequirements: [TestEntryConfiguration]
    let timeout: TimeInterval
    
    var description: String {
        "Some worker requirements cannot be met after waiting for \(LoggableDuration(timeout)) for any worker with suitable capabilities to appear: " +
            testEntryConfigurationsWithUnmetRequirements.map { "\($0)" }.joined(separator: ", ")
    }
}
