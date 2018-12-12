import Dispatch
import Foundation
import Logging
import Models
import RESTMethods
import WorkerAlivenessTracker

public final class WorkerRegistrar: RESTEndpoint {
    private let workerConfigurations: WorkerConfigurations
    private let workerAlivenessTracker: WorkerAlivenessTracker
    
    public enum WorkerRegistrarError: Swift.Error, CustomStringConvertible {
        case missingWorkerConfiguration(workerId: String)
        case workerIsBlocked(workerId: String)
        public var description: String {
            switch self {
            case .missingWorkerConfiguration(let workerId):
                return "Missing worker configuration for worker id: '\(workerId)'"
            case .workerIsBlocked(let workerId):
                return "Can't register worker '\(workerId)' because it has been blocked"
            }
        }
    }
    
    public init(workerConfigurations: WorkerConfigurations, workerAlivenessTracker: WorkerAlivenessTracker) {
        self.workerConfigurations = workerConfigurations
        self.workerAlivenessTracker = workerAlivenessTracker
    }
    
    public func handle(decodedRequest: RegisterWorkerRequest) throws -> RegisterWorkerResponse {
        guard let workerConfiguration = workerConfigurations.workerConfiguration(workerId: decodedRequest.workerId) else {
            throw WorkerRegistrarError.missingWorkerConfiguration(workerId: decodedRequest.workerId)
        }
        
        let workerAliveness = workerAlivenessTracker.alivenessForWorker(workerId: decodedRequest.workerId)
        switch workerAliveness.status {
        case .notRegistered, .alive, .silent:
            log("Registration request from worker with id: \(decodedRequest.workerId)")
            workerAlivenessTracker.didRegisterWorker(workerId: decodedRequest.workerId)
            return .workerRegisterSuccess(workerConfiguration: workerConfiguration)
        case .blocked:
            throw WorkerRegistrarError.workerIsBlocked(workerId: decodedRequest.workerId)
        }
    }
}
