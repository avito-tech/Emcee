import Dispatch
import Foundation

public final class WorkerAlivenessTracker: WorkerAlivenessProvider {
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.WorkerAlivenessTracker.syncQueue")
    private var workerAliveReportTimestamps = [String: Date]()
    private var blockedWorkers = Set<String>()
    private let reportAliveInterval: TimeInterval
    /// allow worker some additinal time to perform a "i'm alive" report, e.g. to compensate a network latency
    private let additionalTimeToPerformWorkerIsAliveReport: TimeInterval

    public init(reportAliveInterval: TimeInterval, additionalTimeToPerformWorkerIsAliveReport: TimeInterval = 10.0) {
        self.reportAliveInterval = reportAliveInterval
        self.additionalTimeToPerformWorkerIsAliveReport = additionalTimeToPerformWorkerIsAliveReport
    }

    public func workerIsAlive(workerId: String) {
        syncQueue.sync {
            if !blockedWorkers.contains(workerId) {
                workerAliveReportTimestamps[workerId] = Date()
            }
        }
    }
    
    public func didRegisterWorker(workerId: String) {
        workerIsAlive(workerId: workerId)
    }
    
    public func didBlockWorker(workerId: String) {
        syncQueue.sync {
            _ = blockedWorkers.insert(workerId)
        }
    }
    
    public func alivenessForWorker(workerId: String) -> WorkerAliveness {
        return syncQueue.sync {
            guard let latestAliveDate = workerAliveReportTimestamps[workerId] else {
                return .notRegistered
            }
            if blockedWorkers.contains(workerId) {
                return .blocked
            }
            let silenceDuration = Date().timeIntervalSince(latestAliveDate)
            if silenceDuration > maximumNotReportingDuration {
                return .silent
            } else {
                return .alive
            }
        }
    }
    
    public var hasAnyAliveWorker: Bool {
        let workers = syncQueue.sync { workerAliveReportTimestamps.keys }
        for workerId in workers {
            if alivenessForWorker(workerId: workerId) == .alive {
                return true
            }
        }
        return false
    }
    
    private var maximumNotReportingDuration: TimeInterval {
        return reportAliveInterval + additionalTimeToPerformWorkerIsAliveReport
    }
}
