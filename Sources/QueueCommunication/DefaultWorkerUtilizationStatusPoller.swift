import AtomicModels
import Deployer
import LocalHostDeterminer
import Logging
import Metrics
import Models
import Timer

public class DefaultWorkerUtilizationStatusPoller: WorkerUtilizationStatusPoller {
    private let communicationService: QueueCommunicationService
    private let defaultDeployments: [DeploymentDestination]
    private var workerIdsToUtilize: AtomicValue<Set<WorkerId>>
    private let pollingTrigger = DispatchBasedTimer(repeating: .seconds(60), leeway: .seconds(10))
    private let emceeVersion: Version
    private let queueHost: String
    
    public init(
        emceeVersion: Version,
        queueHost: String,
        defaultDeployments: [DeploymentDestination],
        communicationService: QueueCommunicationService
    ) {
        self.defaultDeployments = defaultDeployments
        self.communicationService = communicationService
        self.workerIdsToUtilize = AtomicValue(Set(defaultDeployments.map { $0.workerId }))
        self.emceeVersion = emceeVersion
        self.queueHost = queueHost
        MetricRecorder.capture(
            NumberOfWorkersToUtilizeMetric(emceeVersion: emceeVersion, queueHost: queueHost, workersCount: defaultDeployments.count)
        )
    }
    
    public func startPolling() {
        pollingTrigger.start { [weak self] timer in
            self?.fetchWorkersToUtilize()
        }
    }
    
    public func stopPollingAndRestoreDefaultConfig() {
        pollingTrigger.stop()
        self.workerIdsToUtilize.set(Set(defaultDeployments.map { $0.workerId }))
        MetricRecorder.capture(
            NumberOfWorkersToUtilizeMetric(emceeVersion: emceeVersion, queueHost: queueHost, workersCount: defaultDeployments.count)
        )
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
                    MetricRecorder.capture(
                        NumberOfWorkersToUtilizeMetric(
                            emceeVersion: strongSelf.emceeVersion,
                            queueHost: strongSelf.queueHost,
                            workersCount: workerIds.count
                        )
                    )
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
