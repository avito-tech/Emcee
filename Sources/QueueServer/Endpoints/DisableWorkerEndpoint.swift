import Dispatch
import DistWorkerModels
import Foundation
import Logging
import Models
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class DisableWorkerEndpoint: RESTEndpoint {
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerConfigurations: WorkerConfigurations
    
    public enum DisableWorkerError: Swift.Error, CustomStringConvertible {
        case missingWorkerConfiguration(workerId: WorkerId)
        case workerIsAlreadyDisabled(workerId: WorkerId)
        
        public var description: String {
            switch self {
            case .missingWorkerConfiguration(let workerId):
                return "Missing worker configuration for \(workerId)"
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
    
    public func handle(decodedPayload: DisableWorkerPayload) throws -> WorkerDisabledResponse {
        guard workerConfigurations.workerConfiguration(workerId: decodedPayload.workerId) != nil else {
            throw DisableWorkerError.missingWorkerConfiguration(workerId: decodedPayload.workerId)
        }
        Logger.debug("Request to disable worker with id: \(decodedPayload.workerId)")
        
        guard workerAlivenessProvider.alivenessForWorker(workerId: decodedPayload.workerId).status != .disabled else {
            throw DisableWorkerError.workerIsAlreadyDisabled(workerId: decodedPayload.workerId)
        }
        workerAlivenessProvider.disableWorker(workerId: decodedPayload.workerId)
        
        return WorkerDisabledResponse(workerId: decodedPayload.workerId)
    }
}
