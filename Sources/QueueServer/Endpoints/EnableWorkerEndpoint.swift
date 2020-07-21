import Dispatch
import DistWorkerModels
import Foundation
import Logging
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class EnableWorkerEndpoint: RESTEndpoint {
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerConfigurations: WorkerConfigurations
    public let path: RESTPath = RESTMethod.enableWorker
    public let requestIndicatesActivity = false
    
    public enum EnableWorkerError: Swift.Error, CustomStringConvertible {
        case workerIsAlreadyEnabled(workerId: WorkerId)
        
        public var description: String {
            switch self {
            case .workerIsAlreadyEnabled(let workerId):
                return "Can't disable \(workerId) because it is already enabled"
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
    
    public func handle(payload: EnableWorkerPayload) throws -> WorkerEnabledResponse {
        guard workerConfigurations.workerConfiguration(workerId: payload.workerId) != nil else {
            throw WorkerConfigurationError.missingWorkerConfiguration(workerId: payload.workerId)
        }
        Logger.debug("Request to enable worker with id: \(payload.workerId)")
        
        guard workerAlivenessProvider.alivenessForWorker(workerId: payload.workerId).disabled else {
            throw EnableWorkerError.workerIsAlreadyEnabled(workerId: payload.workerId)
        }
        workerAlivenessProvider.enableWorker(workerId: payload.workerId)
        
        return WorkerEnabledResponse(workerId: payload.workerId)
    }
}
