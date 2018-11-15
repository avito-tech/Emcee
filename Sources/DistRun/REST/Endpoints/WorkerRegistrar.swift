import Dispatch
import Foundation
import Logging
import Models
import RESTMethods

public final class WorkerRegistrar: RESTEndpoint {
    public typealias T = RegisterWorkerRequest
    private let workerConfigurations: WorkerConfigurations
    private let workerAlivenessTracker: WorkerAlivenessTracker
    private let queue = DispatchQueue(label: "ru.avito.emcee.WorkerRegistrar.queue")
    private var registeredWorkers = Set<String>()
    private var blockedWorkers = Set<String>()
    
    public enum Availability: Equatable {
        case available(WorkerConfiguration)
        case blocked
        case unavailable
    }
    
    public enum WorkerRegistrarError: Swift.Error, CustomStringConvertible {
        case missingWorkerConfiguration(workerId: String)
        public var description: String {
            switch self {
            case .missingWorkerConfiguration(let workerId):
                return "Missing worker configuration for worker id: '\(workerId)'"
            }
        }
    }
    
    public init(workerConfigurations: WorkerConfigurations, workerAlivenessTracker: WorkerAlivenessTracker) {
        self.workerConfigurations = workerConfigurations
        self.workerAlivenessTracker = workerAlivenessTracker
    }
    
    public func handle(decodedRequest: RegisterWorkerRequest) throws -> RESTResponse {
        let configurationAvailability = workerConfigurationAvailability(workerId: decodedRequest.workerId)
        switch configurationAvailability {
        case .available(let workerConfiguration):
            log("Registration request from worker with id: \(decodedRequest.workerId)")
            markWorkerAsRegistered(workerId: decodedRequest.workerId)
            workerAlivenessTracker.didRegisterWorker(workerId: decodedRequest.workerId)
            return .workerRegisterSuccess(workerConfiguration: workerConfiguration)
        case .blocked:
            return .workerBlocked
        case .unavailable:
            throw WorkerRegistrarError.missingWorkerConfiguration(workerId: decodedRequest.workerId)
        }
    }
    
    private func markWorkerAsRegistered(workerId: String) {
        queue.sync {
            guard !blockedWorkers.contains(workerId) else { return }
            registeredWorkers.insert(workerId)
        }
    }
    
    public func isWorkerRegistered(workerId: String) -> Bool {
        return queue.sync { registeredWorkers.contains(workerId) }
    }
    
    public var hasAnyRegisteredWorkers: Bool {
        return queue.sync { !registeredWorkers.isEmpty }
    }
    
    public func blockWorker(workerId: String) {
        queue.sync {
            registeredWorkers.remove(workerId)
            blockedWorkers.insert(workerId)
        }
    }
    
    public func isWorkerBlocked(workerId: String) -> Bool {
        return queue.sync { blockedWorkers.contains(workerId) }
    }
    
    public func workerConfigurationAvailability(workerId: String) -> Availability {
        return queue.sync {
            if blockedWorkers.contains(workerId) {
                return .blocked
            }
            if let workerConfiguration = workerConfigurations.workerConfiguration(workerId: workerId) {
                return .available(workerConfiguration)
            } else {
                return .unavailable
            }
        }
    }
}
