import AtomicModels
import Deployer
import LocalHostDeterminer
import Logging
import Metrics
import QueueModels
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
        self.workerIdsToUtilize = AtomicValue(Set(defaultDeployments.workerIds()))
        self.emceeVersion = emceeVersion
        self.queueHost = queueHost
        MetricRecorder.capture(
            NumberOfWorkersToUtilizeMetric(emceeVersion: emceeVersion, queueHost: queueHost, workersCount: defaultDeployments.count)
        )
    }
    
    public func startPolling() {
        Logger.debug("Starting polling workers to utilize")
        pollingTrigger.start { [weak self] timer in
            Logger.debug("Fetching workers to utilize")
            self?.fetchWorkersToUtilize()
        }
    }
    
    public func stopPollingAndRestoreDefaultConfig() {
        Logger.debug("Stopping polling workers to utilize")
        pollingTrigger.stop()
        self.workerIdsToUtilize.set(Set(defaultDeployments.workerIds()))
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
                    Logger.debug("Fetched workerIds to utilize: \(workerIds)")
                    strongSelf.workerIdsToUtilize.set(workerIds)
                    MetricRecorder.capture(
                        NumberOfWorkersToUtilizeMetric(
                            emceeVersion: strongSelf.emceeVersion,
                            queueHost: strongSelf.queueHost,
                            workersCount: workerIds.count
                        )
                    )
                } catch {
                    Logger.error("Failed to fetch workers to utilize: \(error)")
                }
        })
    }
    
    public func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission {
        return workerIdsToUtilize.withExclusiveAccess { workerIds in
            return workerIds.contains(workerId) ? .allowedToUtilize : .notAllowedToUtilize
        }
    }
}
