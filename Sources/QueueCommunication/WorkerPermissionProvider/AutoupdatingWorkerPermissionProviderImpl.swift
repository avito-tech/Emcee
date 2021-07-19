import AtomicModels
import Deployer
import LocalHostDeterminer
import EmceeLogging
import Metrics
import MetricsExtensions
import QueueCommunicationModels
import QueueModels
import Timer

public class AutoupdatingWorkerPermissionProviderImpl: AutoupdatingWorkerPermissionProvider {
    private let communicationService: QueueCommunicationService
    private let initialWorkerIds: Set<WorkerId>
    private let emceeVersion: Version
    private let logger: ContextualLogger
    private let globalMetricRecorder: GlobalMetricRecorder
    private let pollingTrigger = DispatchBasedTimer(repeating: .seconds(60), leeway: .seconds(10))
    private let queueHost: String
    private let workerIdsToUtilize: AtomicValue<Set<WorkerId>>
    
    public init(
        communicationService: QueueCommunicationService,
        initialWorkerIds: Set<WorkerId>,
        emceeVersion: Version,
        logger: ContextualLogger,
        globalMetricRecorder: GlobalMetricRecorder,
        queueHost: String
    ) {
        self.communicationService = communicationService
        self.initialWorkerIds = initialWorkerIds
        self.emceeVersion = emceeVersion
        self.logger = logger
        self.globalMetricRecorder = globalMetricRecorder
        self.queueHost = queueHost
        self.workerIdsToUtilize = AtomicValue(initialWorkerIds)
        reportMetric()
    }
    
    public func startUpdating() {
        logger.debug("Starting polling workers to utilize")
        pollingTrigger.start { [weak self] timer in
            guard let strongSelf = self else {
                return timer.stop()
            }
            
            strongSelf.logger.debug("Fetching workers to utilize")
            strongSelf.fetchWorkersToUtilize()
        }
    }
    
    public func stopUpdatingAndRestoreDefaultConfig() {
        logger.debug("Stopping polling workers to utilize")
        pollingTrigger.stop()
        workerIdsToUtilize.set(initialWorkerIds)
        reportMetric()
    }
    
    private func fetchWorkersToUtilize() {
        communicationService.workersToUtilize(
            version: emceeVersion,
            workerIds: initialWorkerIds
        ) { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            do {
                let workerIds = try result.dematerialize()
                strongSelf.logger.debug("Fetched workerIds to utilize: \(workerIds)")
                strongSelf.workerIdsToUtilize.set(workerIds)
                strongSelf.reportMetric()
            } catch {
                strongSelf.logger.error("Failed to fetch workers to utilize: \(error)")
            }
        }
    }
    
    public func utilizationPermissionForWorker(workerId: WorkerId) -> WorkerUtilizationPermission {
        workerIdsToUtilize.currentValue().contains(workerId) ? .allowedToUtilize : .notAllowedToUtilize
    }
    
    private func reportMetric() {
        globalMetricRecorder.capture(
            NumberOfWorkersToUtilizeMetric(
                emceeVersion: emceeVersion,
                queueHost: queueHost,
                workersCount: workerIdsToUtilize.currentValue().count
            )
        )
    }
}
