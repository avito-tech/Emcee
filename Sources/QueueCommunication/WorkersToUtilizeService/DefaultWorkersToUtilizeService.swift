import Deployer
import Foundation
import Logging
import QueueModels
import RemotePortDeterminer

public class DefaultWorkersToUtilizeService: WorkersToUtilizeService {
    private let cache: WorkersMappingCache
    private let calculator: WorkersToUtilizeCalculator
    private let communicationService: QueueCommunicationService
    private let portDeterminer: RemotePortDeterminer
    
    public init(
        cache: WorkersMappingCache,
        calculator: WorkersToUtilizeCalculator,
        communicationService: QueueCommunicationService,
        portDeterminer: RemotePortDeterminer
    ) {
        self.cache = cache
        self.calculator = calculator
        self.communicationService = communicationService
        self.portDeterminer = portDeterminer
    }
    
    public func workersToUtilize(initialWorkers: [WorkerId], version: Version) -> [WorkerId] {
        Logger.debug("Preparing workers to utilize for version \(version) with initial workers \(initialWorkers)")
        
        if let cachedWorkers = cache.cachedMapping()?[version] {
            Logger.info("Use cached workers to utilize: \(cachedWorkers) for version: \(version)")
            return cachedWorkers
        }
        
        let mappings = calculator.disjointWorkers(mapping: composeQueuesMapping())
        cache.cacheMapping(mappings)
        
        guard let workers = mappings[version] else {
            Logger.error("Not found workers mapping for version \(version)")
            return initialWorkers
        }
        
        Logger.info("Use workers to utilize: \(workers) for version: \(version)")
        return workers
    }
    
    private func composeQueuesMapping() -> WorkersPerVersion {
        let portToVersion = portDeterminer.queryPortAndQueueServerVersion(timeout: 30)
        var mapping = WorkersPerVersion()
        let dispatchGroup = DispatchGroup()

        for (port, version) in portToVersion {
            dispatchGroup.enter()
            communicationService.deploymentDestinations(port: port) { result in
                defer { dispatchGroup.leave() }
                do {
                    let workers = try result.dematerialize().workerIds()
                    mapping[version] = workers
                } catch {
                    Logger.error("Error in obtaining deployment destinations for queue at port \(port) with error \(error.localizedDescription)")
                }
            }
        }
        
        dispatchGroup.wait()
        return mapping
    }
}
