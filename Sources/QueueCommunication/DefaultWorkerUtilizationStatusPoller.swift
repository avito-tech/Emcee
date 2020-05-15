import AtomicModels
import Deployer
import Logging
import Models
import Timer

public class DefaultWorkerUtilizationStatusPoller: WorkerUtilizationStatusPoller {
    private let communicationService: QueueCommunicationService
    private let defaultDeployments: [DeploymentDestination]
    private var workerIdsToUtilize: AtomicValue<Set<WorkerId>>
    private let pollingTrigger = DispatchBasedTimer(repeating: .seconds(60), leeway: .seconds(10))
    
    public init(
        defaultDeployments: [DeploymentDestination],
        communicationService: QueueCommunicationService
    ) {
        self.defaultDeployments = defaultDeployments
        self.communicationService = communicationService
        self.workerIdsToUtilize = AtomicValue(Set(defaultDeployments.map { $0.workerId }))
    }
    
    public func startPolling() {
        pollingTrigger.start { [weak self] timer in
            self?.fetchWorkersToUtilize()
        }
    }
    
    private func fetchWorkersToUtilize() {
        communicationService.workersToUtilize(
            deployments: defaultDeployments,
            completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                
                do {
                    let workerIds = try result.dematerialize()
                    Logger.debug("Fetched workerIds to utilize:\(workerIds)")
                    strongSelf.workerIdsToUtilize.set(workerIds)
                } catch {
                    Logger.error(error.localizedDescription)
                }
        })
    }
    
    public func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission {
        return workerIdsToUtilize.withExclusiveAccess { workerIds in
            return workerIds.contains(workerId) ? .allowedToUtilize : .notAllowedToUtilize
        }
    }
}
