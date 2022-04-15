import AtomicModels
import EmceeLogging
import MetricsRecording
import MetricsExtensions
import QueueCommunicationModels
import QueueModels
import QueueServerPortProvider
import SocketModels
import Timer

public class AutoupdatingWorkerPermissionProviderImpl: AutoupdatingWorkerPermissionProvider {
    private let communicationService: QueueCommunicationService
    private let initialWorkerIds: Set<WorkerId>
    private let emceeVersion: Version
    private let logger: ContextualLogger
    private let globalMetricRecorder: GlobalMetricRecorder
    private let pollingTrigger = DispatchBasedTimer(repeating: .seconds(60), leeway: .seconds(10))
    private let queueHost: String
    private let queueServerPortProvider: QueueServerPortProvider
    private let workerIdsToUtilize: AtomicValue<Set<WorkerId>>
    
    public init(
        communicationService: QueueCommunicationService,
        initialWorkerIds: Set<WorkerId>,
        emceeVersion: Version,
        logger: ContextualLogger,
        globalMetricRecorder: GlobalMetricRecorder,
        queueHost: String,
        queueServerPortProvider: QueueServerPortProvider
    ) {
        self.communicationService = communicationService
        self.initialWorkerIds = initialWorkerIds
        self.emceeVersion = emceeVersion
        self.logger = logger
        self.globalMetricRecorder = globalMetricRecorder
        self.queueHost = queueHost
        self.workerIdsToUtilize = AtomicValue(initialWorkerIds)
        self.queueServerPortProvider = queueServerPortProvider
        reportMetric()
    }
    
    public func startUpdating() {
        logger.trace("Starting polling workers to utilize")
        pollingTrigger.start { [weak self] timer in
            guard let strongSelf = self else {
                return timer.stop()
            }
            
            strongSelf.logger.trace("Fetching workers to utilize")
            strongSelf.fetchWorkersToUtilize()
        }
    }
    
    public func stopUpdatingAndRestoreDefaultConfig() {
        logger.trace("Stopping polling workers to utilize")
        pollingTrigger.stop()
        workerIdsToUtilize.set(initialWorkerIds)
        reportMetric()
    }
    
    private func fetchWorkersToUtilize() {
        let queuePort: SocketModels.Port
        do {
            queuePort = try queueServerPortProvider.port()
        } catch {
            logger.warning("Failed to get current queue port: \(error). This error will be ignored.")
            return
        }
        
        communicationService.workersToUtilize(
            queueInfo: QueueInfo(
                queueAddress: SocketAddress(host: queueHost, port: queuePort),
                queueVersion: emceeVersion
            ),
            workerIds: initialWorkerIds,
            completion: { [weak self] result in
                guard let strongSelf = self else { return }
                
                do {
                    let workerIds = try result.dematerialize()
                    strongSelf.logger.debug("Fetched workerIds to utilize: \(workerIds.map(\.value).sorted())")
                    strongSelf.workerIdsToUtilize.set(workerIds)
                    strongSelf.reportMetric()
                } catch {
                    strongSelf.logger.error("Failed to fetch workers to utilize: \(error)")
                }
            }
        )
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
