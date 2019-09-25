import DateProvider
import DateProviderTestHelpers
import Foundation
import WorkerAlivenessProvider

public final class WorkerAlivenessProviderFixtures {
    public static func alivenessTrackerWithAlwaysAliveResults(
        dateProvider: DateProvider = DateProviderFixture()
    ) -> WorkerAlivenessProvider {
        return WorkerAlivenessProviderImpl(
            dateProvider: dateProvider,
            reportAliveInterval: .infinity,
            additionalTimeToPerformWorkerIsAliveReport: .infinity
        )
    }
    
    public static func alivenessTrackerWithImmediateTimeout(
        dateProvider: DateProvider = DateProviderFixture()
    ) -> WorkerAlivenessProvider {
        return WorkerAlivenessProviderImpl(
            dateProvider: dateProvider,
            reportAliveInterval: 0.0,
            additionalTimeToPerformWorkerIsAliveReport: 0.0
        )
    }
}
