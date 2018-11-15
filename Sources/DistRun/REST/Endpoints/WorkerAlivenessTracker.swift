import Dispatch
import Foundation
import Models
import RESTMethods

public final class WorkerAlivenessTracker {
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.WorkerAlivenessTracker.syncQueue")
    private var workerAliveReportTimestamps = [String: Date]()
    private let reportAliveInterval: TimeInterval
    /// allow worker some additinal time to perform a "i'm alive" report, e.g. to compensate a network latency
    private let additionalTimeToPerformWorkerIsAliveReport: TimeInterval
    
    public enum WorkerAliveness: Equatable {
        case alive
        case silent
        case blockedOrNotRegistered
    }

    public init(reportAliveInterval: TimeInterval, additionalTimeToPerformWorkerIsAliveReport: TimeInterval = 10.0) {
        self.reportAliveInterval = reportAliveInterval
        self.additionalTimeToPerformWorkerIsAliveReport = additionalTimeToPerformWorkerIsAliveReport
    }

    public func workerIsAlive(workerId: String) {
        syncQueue.sync {
            workerAliveReportTimestamps[workerId] = Date()
        }
    }
    
    public func didRegisterWorker(workerId: String) {
        workerIsAlive(workerId: workerId)
    }
    
    public func didBlockWorker(workerId: String) {
        syncQueue.sync {
            _ = workerAliveReportTimestamps.removeValue(forKey: workerId)
        }
    }
    
    public func alivenessForWorker(workerId: String) -> WorkerAliveness {
        return syncQueue.sync {
            guard let latestAliveDate = workerAliveReportTimestamps[workerId] else {
                return .blockedOrNotRegistered
            }
            let silenceDuration = Date().timeIntervalSince(latestAliveDate)
            if silenceDuration > maximumNotReportingDuration {
                return .silent
            } else {
                return .alive
            }
        }
    }
    
    private var maximumNotReportingDuration: TimeInterval {
        return reportAliveInterval + additionalTimeToPerformWorkerIsAliveReport
    }
}
