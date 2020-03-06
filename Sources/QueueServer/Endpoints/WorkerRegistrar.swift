import Dispatch
import DistWorkerModels
import Foundation
import Logging
import Models
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class WorkerRegistrar: RESTEndpoint {
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerConfigurations: WorkerConfigurations
    private let workerDetailsHolder: WorkerDetailsHolder
    
    public enum WorkerRegistrarError: Swift.Error, CustomStringConvertible {
        case missingWorkerConfiguration(workerId: WorkerId)
        case workerIsBlocked(workerId: WorkerId)
        case workerIsAlreadyRegistered(workerId: WorkerId)
        
        public var description: String {
            switch self {
            case .missingWorkerConfiguration(let workerId):
                return "Missing worker configuration for \(workerId)"
            case .workerIsBlocked(let workerId):
                return "Can't register \(workerId) because it has been blocked"
            case .workerIsAlreadyRegistered(let workerId):
                return "Can't register \(workerId) because it is already registered"
            }
        }
    }
    
    public init(
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerConfigurations: WorkerConfigurations,
        workerDetailsHolder: WorkerDetailsHolder
    ) {
        self.workerAlivenessProvider = workerAlivenessProvider
        self.workerConfigurations = workerConfigurations
        self.workerDetailsHolder = workerDetailsHolder
    }
    
    public func handle(decodedPayload: RegisterWorkerPayload) throws -> RegisterWorkerResponse {
        guard let workerConfiguration = workerConfigurations.workerConfiguration(workerId: decodedPayload.workerId) else {
            throw WorkerRegistrarError.missingWorkerConfiguration(workerId: decodedPayload.workerId)
        }
        Logger.debug("Registration request from worker with id: \(decodedPayload.workerId)")
        
        let workerAliveness = workerAlivenessProvider.alivenessForWorker(workerId: decodedPayload.workerId)
        switch workerAliveness.status {
        case .notRegistered, .silent:
            workerAlivenessProvider.didRegisterWorker(workerId: decodedPayload.workerId)
            Logger.debug("Worker \(decodedPayload.workerId) has acceptable status")
            workerDetailsHolder.update(
                workerId: decodedPayload.workerId,
                restAddress: decodedPayload.workerRestAddress
            )
            return .workerRegisterSuccess(workerConfiguration: workerConfiguration)
        case .alive:
            throw WorkerRegistrarError.workerIsAlreadyRegistered(workerId: decodedPayload.workerId)
        case .blocked:
            throw WorkerRegistrarError.workerIsBlocked(workerId: decodedPayload.workerId)
        }
    }
}
