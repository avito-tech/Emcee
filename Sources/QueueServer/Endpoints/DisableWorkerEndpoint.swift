import Dispatch
import DistWorkerModels
import Foundation
import Logging
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class DisableWorkerEndpoint: RESTEndpoint {
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerConfigurations: WorkerConfigurations
    public let path: RESTPath = RESTMethod.disableWorker
    public let requestIndicatesActivity = false
    
    public enum DisableWorkerError: Swift.Error, CustomStringConvertible {
        case workerIsAlreadyDisabled(workerId: WorkerId)
        
        public var description: String {
            switch self {
            case .workerIsAlreadyDisabled(let workerId):
                return "Can't disable \(workerId) because it is already disabled"
            }
        }
    }
    
    public init(
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerConfigurations: WorkerConfigurations
    ) {
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerConfigurations = workerConfigurations
    }
    
    public func handle(payload: DisableWorkerPayload) throws -> WorkerDisabledResponse {
        guard workerConfigurations.workerConfiguration(workerId: payload.workerId) != nil else {
            throw WorkerConfigurationError.missingWorkerConfiguration(workerId: payload.workerId)
        }
        Logger.debug("Request to disable worker with id: \(payload.workerId)")
        
        guard workerAlivenessProvider.alivenessForWorker(workerId: payload.workerId).enabled else {
            throw DisableWorkerError.workerIsAlreadyDisabled(workerId: payload.workerId)
        }
        workerAlivenessProvider.disableWorker(workerId: payload.workerId)
        
        return WorkerDisabledResponse(workerId: payload.workerId)
    }
}
