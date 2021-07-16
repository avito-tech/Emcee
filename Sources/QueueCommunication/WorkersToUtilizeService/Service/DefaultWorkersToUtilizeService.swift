import AtomicModels
import Foundation
import EmceeLogging
import QueueModels
import RemotePortDeterminer

public class DefaultWorkersToUtilizeService: WorkersToUtilizeService {
    private let cache: WorkersMappingCache
    private let calculator: WorkersToUtilizeCalculator
    private let communicationService: QueueCommunicationService
    private let logger: ContextualLogger
    private let portDeterminer: RemotePortDeterminer
    
    public init(
        cache: WorkersMappingCache,
        calculator: WorkersToUtilizeCalculator,
        communicationService: QueueCommunicationService,
        logger: ContextualLogger,
        portDeterminer: RemotePortDeterminer
    ) {
        self.cache = cache
        self.calculator = calculator
        self.communicationService = communicationService
        self.logger = logger
        self.portDeterminer = portDeterminer
    }
    
    public func workersToUtilize(
        initialWorkerIds: Set<WorkerId>,
        queueInfo: QueueInfo
    ) -> Set<WorkerId> {
        logger.debug("Preparing workers to utilize for queue \(queueInfo.queueAddress) \(queueInfo.queueVersion) with initial workers \(initialWorkerIds.sorted())")
        
        if let cachedWorkers = cache.cachedMapping()?[queueInfo] {
            logger.debug("Use cached workers to utilize: \(cachedWorkers) for version: \(queueInfo.queueVersion)")
            return cachedWorkers
        }
        
        let mapping = calculator.disjointWorkers(mapping: composeQueuesMapping())
        cache.cache(mapping: mapping)
        
        guard let workers = mapping[queueInfo] else {
            logger.error("Not found workers mapping for version \(queueInfo.queueVersion)")
            return initialWorkerIds
        }
        
        logger.debug("Use workers to utilize: \(workers) for queue \(queueInfo.queueAddress) \(queueInfo.queueVersion)")
        return workers
    }
    
    private func composeQueuesMapping() -> WorkersPerQueue {
        let socketToVersion = portDeterminer.queryPortAndQueueServerVersion(timeout: 30)
        let mapping = AtomicValue(WorkersPerQueue())
        let dispatchGroup = DispatchGroup()

        for (socketAddress, version) in socketToVersion {
            let queueInfo = QueueInfo(queueAddress: socketAddress, queueVersion: version)
            dispatchGroup.enter()
            communicationService.queryQueueForWorkerIds(queueAddress: socketAddress) { [logger] result in
                defer { dispatchGroup.leave() }
                do {
                    try mapping.withExclusiveAccess {
                        $0[queueInfo] = try result.dematerialize()
                    }
                } catch {
                    logger.error("Error obtaining workers for queue at \(socketAddress): \(error)")
                }
            }
        }
        
        dispatchGroup.wait()
        return mapping.currentValue()
    }
}
