import Dispatch
import Foundation
import Logging
import Models
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class WorkerRegistrar: RESTEndpoint {
    private let workerConfigurations: WorkerConfigurations
    private let workerAlivenessProvider: WorkerAlivenessProvider
    
    public enum WorkerRegistrarError: Swift.Error, CustomStringConvertible {
        case missingWorkerConfiguration(workerId: WorkerId)
        case workerIsBlocked(workerId: WorkerId)
        public var description: String {
            switch self {
            case .missingWorkerConfiguration(let workerId):
                return "Missing worker configuration for \(workerId)"
            case .workerIsBlocked(let workerId):
                return "Can't register \(workerId) because it has been blocked"
            }
        }
    }
    
    public init(workerConfigurations: WorkerConfigurations, workerAlivenessProvider: WorkerAlivenessProvider) {
        self.workerConfigurations = workerConfigurations
        self.workerAlivenessProvider = workerAlivenessProvider
    }
    
    public func handle(decodedRequest: RegisterWorkerRequest) throws -> RegisterWorkerResponse {
        guard let workerConfiguration = workerConfigurations.workerConfiguration(workerId: decodedRequest.workerId) else {
            throw WorkerRegistrarError.missingWorkerConfiguration(workerId: decodedRequest.workerId)
        }
        
        let workerAliveness = workerAlivenessProvider.alivenessForWorker(workerId: decodedRequest.workerId)
        switch workerAliveness.status {
        case .notRegistered, .alive, .silent:
            Logger.debug("Registration request from worker with id: \(decodedRequest.workerId)")
            workerAlivenessProvider.didRegisterWorker(workerId: decodedRequest.workerId)
            return .workerRegisterSuccess(workerConfiguration: workerConfiguration)
        case .blocked:
            throw WorkerRegistrarError.workerIsBlocked(workerId: decodedRequest.workerId)
        }
    }
}
