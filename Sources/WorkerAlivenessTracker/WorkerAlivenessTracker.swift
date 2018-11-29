import Dispatch
import Foundation

public final class WorkerAlivenessTracker: WorkerAlivenessProvider {
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.WorkerAlivenessTracker.syncQueue")
    private var workerAliveReportTimestamps = [String: Date]()
    private var blockedWorkers = Set<String>()
    private let reportAliveInterval: TimeInterval
    /// allow worker some additinal time to perform a "i'm alive" report, e.g. to compensate a network latency
    private let additionalTimeToPerformWorkerIsAliveReport: TimeInterval

    public init(reportAliveInterval: TimeInterval, additionalTimeToPerformWorkerIsAliveReport: TimeInterval) {
        self.reportAliveInterval = reportAliveInterval
        self.additionalTimeToPerformWorkerIsAliveReport = additionalTimeToPerformWorkerIsAliveReport
    }

    public func markWorkerAsAlive(workerId: String) {
        syncQueue.sync {
            if !blockedWorkers.contains(workerId) {
                workerAliveReportTimestamps[workerId] = Date()
            }
        }
    }
    
    public func didRegisterWorker(workerId: String) {
        markWorkerAsAlive(workerId: workerId)
    }
    
    public func blockWorker(workerId: String) {
        syncQueue.sync {
            _ = blockedWorkers.insert(workerId)
        }
    }
    
    public var workerAliveness: [String: WorkerAliveness] {
        return syncQueue.sync {
            let uniqueWorkerIds = Set<String>(workerAliveReportTimestamps.keys).union(blockedWorkers)
            
            var workerAliveness = [String: WorkerAliveness]()
            let currentDate = Date()
            for id in uniqueWorkerIds {
                workerAliveness[id] = alivenessForWorker(workerId: id, currentDate: currentDate)
            }
            return workerAliveness
        }
    }
    
    private func alivenessForWorker(workerId: String, currentDate: Date) -> WorkerAliveness {
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
    
    private var maximumNotReportingDuration: TimeInterval {
        return reportAliveInterval + additionalTimeToPerformWorkerIsAliveReport
    }
}
