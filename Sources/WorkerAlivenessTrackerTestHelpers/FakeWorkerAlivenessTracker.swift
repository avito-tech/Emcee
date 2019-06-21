import DateProvider
import DateProviderTestHelpers
import Foundation
import WorkerAlivenessTracker

public final class WorkerAlivenessTrackerFixtures {
    public static func alivenessTrackerWithAlwaysAliveResults() -> WorkerAlivenessTracker {
        return WorkerAlivenessTracker(
            dateProvider: DateProviderFixture(),
            reportAliveInterval: .infinity,
            additionalTimeToPerformWorkerIsAliveReport: .infinity
        )
    }
    
    public static func alivenessTrackerWithImmediateTimeout() -> WorkerAlivenessTracker {
        return WorkerAlivenessTracker(
            dateProvider: DateProviderFixture(),
            reportAliveInterval: 0.0,
            additionalTimeToPerformWorkerIsAliveReport: 0.0
        )
    }
}
