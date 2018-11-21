import Foundation
import WorkerAlivenessTracker

public final class WorkerAlivenessTrackerFixtures {
    public static func alivenessTrackerWithAlwaysAliveResults() -> WorkerAlivenessTracker {
        return WorkerAlivenessTracker(reportAliveInterval: .infinity, additionalTimeToPerformWorkerIsAliveReport: .infinity)
    }
    
    public static func alivenessTrackerWithImmediateTimeout() -> WorkerAlivenessTracker {
        return WorkerAlivenessTracker(reportAliveInterval: 0.0, additionalTimeToPerformWorkerIsAliveReport: 0.0)
    }
}
