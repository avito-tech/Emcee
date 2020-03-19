import DateProvider
import DateProviderTestHelpers
import Foundation
import Models
import WorkerAlivenessProvider

public final class WorkerAlivenessProviderFixtures {
    public static func alivenessTrackerWithAlwaysAliveResults(
        dateProvider: DateProvider = DateProviderFixture(),
        knownWorkerIds: Set<WorkerId> = []
    ) -> WorkerAlivenessProvider {
        return WorkerAlivenessProviderImpl(
            dateProvider: dateProvider,
            knownWorkerIds: knownWorkerIds,
            reportAliveInterval: .infinity,
            additionalTimeToPerformWorkerIsAliveReport: .infinity
        )
    }
    
    public static func alivenessTrackerWithImmediateTimeout(
        dateProvider: DateProvider = DateProviderFixture()
    ) -> WorkerAlivenessProvider {
        return WorkerAlivenessProviderImpl(
            dateProvider: dateProvider,
            knownWorkerIds: [],
            reportAliveInterval: 0.0,
            additionalTimeToPerformWorkerIsAliveReport: 0.0
        )
    }
}
