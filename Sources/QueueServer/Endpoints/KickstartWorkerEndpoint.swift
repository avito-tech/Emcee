import Dispatch
import DistWorkerModels
import Foundation
import Logging
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class KickstartWorkerEndpoint: RESTEndpoint {
    private let onDemandWorkerStarter: OnDemandWorkerStarter
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerConfigurations: WorkerConfigurations
    public let path: RESTPath = KickstartWorkerRESTMethod()
    public let requestIndicatesActivity = false
    
    public init(
        onDemandWorkerStarter: OnDemandWorkerStarter,
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerConfigurations: WorkerConfigurations
    ) {
        self.onDemandWorkerStarter = onDemandWorkerStarter
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerConfigurations = workerConfigurations
    }
    
    public enum KickstartError: Error, CustomStringConvertible {
        case isAlive(WorkerId)
        
        public var description: String {
            switch self {
            case .isAlive(let workerId):
                return "Can't kickstart \(workerId) because it is alive"
            }
        }
    }
    
    public func handle(payload: KickstartWorkerPayload) throws -> KickstartWorkerResponse {
        guard workerConfigurations.workerConfiguration(workerId: payload.workerId) != nil else {
            throw WorkerConfigurationError.missingWorkerConfiguration(workerId: payload.workerId)
        }
        
        let workerAliveness = workerAlivenessProvider.alivenessForWorker(workerId: payload.workerId)
        guard !workerAliveness.registered || workerAliveness.silent else {
            throw KickstartError.isAlive(payload.workerId)
        }
        
        Logger.debug("Request to kickstart \(payload.workerId)")
        
        try onDemandWorkerStarter.start(workerId: payload.workerId)
        
        return KickstartWorkerResponse(workerId: payload.workerId)
    }
}
