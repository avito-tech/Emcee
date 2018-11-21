import DistRun
import Foundation
import WorkerAlivenessTracker

final class FakeWorkerAlivenessTracker {
    public static func alivenessTrackerWithAlwaysAliveResults() -> WorkerAlivenessTracker {
        return WorkerAlivenessTracker(reportAliveInterval: .infinity)
    }
    
    public static func alivenessTrackerWithImmediateTimeout() -> WorkerAlivenessTracker {
        return WorkerAlivenessTracker(reportAliveInterval: 0.0, additionalTimeToPerformWorkerIsAliveReport: 0.0)
    }
}
