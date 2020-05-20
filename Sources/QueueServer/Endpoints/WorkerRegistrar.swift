import Dispatch
import DistWorkerModels
import Foundation
import Logging
import Models
import RESTInterfaces
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class WorkerRegistrar: RESTEndpoint {
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let workerConfigurations: WorkerConfigurations
    private let workerDetailsHolder: WorkerDetailsHolder
    public let path: RESTPath = RESTMethod.registerWorker
    public let requestIndicatesActivity = true
    
    public enum WorkerRegistrarError: Swift.Error, CustomStringConvertible {
        case missingWorkerConfiguration(workerId: WorkerId)
        case workerIsAlreadyRegistered(workerId: WorkerId)
        
        public var description: String {
            switch self {
            case .missingWorkerConfiguration(let workerId):
                return "Missing worker configuration for \(workerId)"
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
    
    public func handle(payload: RegisterWorkerPayload) throws -> RegisterWorkerResponse {
        guard let workerConfiguration = workerConfigurations.workerConfiguration(workerId: payload.workerId) else {
            throw WorkerRegistrarError.missingWorkerConfiguration(workerId: payload.workerId)
        }
        Logger.debug("Registration request from worker with id: \(payload.workerId)")
        
        let workerAliveness = workerAlivenessProvider.alivenessForWorker(workerId: payload.workerId)
        switch workerAliveness.status {
        case .notRegistered, .silent:
            workerAlivenessProvider.didRegisterWorker(workerId: payload.workerId)
            Logger.debug("Worker \(payload.workerId) has acceptable status")
            workerDetailsHolder.update(
                workerId: payload.workerId,
                restAddress: payload.workerRestAddress
            )
            return .workerRegisterSuccess(workerConfiguration: workerConfiguration)
        case .alive, .disabled:
            throw WorkerRegistrarError.workerIsAlreadyRegistered(workerId: payload.workerId)
        }
    }
}
