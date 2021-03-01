import AtomicModels
import Deployer
import LocalHostDeterminer
import EmceeLogging
import Metrics
import MetricsExtensions
import QueueCommunicationModels
import QueueModels
import Timer

public class DefaultWorkerUtilizationStatusPoller: WorkerUtilizationStatusPoller {
    private let communicationService: QueueCommunicationService
    private let defaultDeployments: [DeploymentDestination]
    private let emceeVersion: Version
    private let globalMetricRecorder: GlobalMetricRecorder
    private let pollingTrigger = DispatchBasedTimer(repeating: .seconds(60), leeway: .seconds(10))
    private let queueHost: String
    private let workerIdsToUtilize: AtomicValue<Set<WorkerId>>
    
    public init(
        communicationService: QueueCommunicationService,
        defaultDeployments: [DeploymentDestination],
        emceeVersion: Version,
        globalMetricRecorder: GlobalMetricRecorder,
        queueHost: String
    ) {
        self.communicationService = communicationService
        self.defaultDeployments = defaultDeployments
        self.emceeVersion = emceeVersion
        self.globalMetricRecorder = globalMetricRecorder
        self.queueHost = queueHost
        self.workerIdsToUtilize = AtomicValue(Set(defaultDeployments.workerIds()))
        reportMetric()
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
        workerIdsToUtilize.set(Set(defaultDeployments.workerIds()))
        reportMetric()
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
                    strongSelf.reportMetric()
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
    
    private func reportMetric() {
        workerIdsToUtilize.withExclusiveAccess {
            globalMetricRecorder.capture(
                NumberOfWorkersToUtilizeMetric(emceeVersion: emceeVersion, queueHost: queueHost, workersCount: $0.count)
            )
        }
    }
}
