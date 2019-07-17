import DateProvider
import DateProviderTestHelpers
import Foundation
import WorkerAlivenessTracker

public final class WorkerAlivenessTrackerFixtures {
    public static func alivenessTrackerWithAlwaysAliveResults(
        dateProvider: DateProvider = DateProviderFixture()
    ) -> WorkerAlivenessTracker {
        return WorkerAlivenessTracker(
            dateProvider: dateProvider,
            reportAliveInterval: .infinity,
            additionalTimeToPerformWorkerIsAliveReport: .infinity
        )
    }
    
    public static func alivenessTrackerWithImmediateTimeout(
        dateProvider: DateProvider = DateProviderFixture()
    ) -> WorkerAlivenessTracker {
        return WorkerAlivenessTracker(
            dateProvider: dateProvider,
            reportAliveInterval: 0.0,
            additionalTimeToPerformWorkerIsAliveReport: 0.0
        )
    }
}
