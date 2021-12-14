import DateProvider
import EmceeLogging
import EmceeTypes
import Foundation
import LocalHostDeterminer
import MetricsExtensions
import QueueModels
import Runner
import RunnerModels
import SimulatorPool
import SimulatorPoolModels

public final class RunAndroidTestsPayloadExecutor {
    private let dateProvider: DateProvider
    
    public init(
        dateProvider: DateProvider
    ) {
        self.dateProvider = dateProvider
    }
    
    public func execute(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketId: BucketId,
        logger: ContextualLogger,
        payload: RunAndroidTestsPayload
    ) -> BucketResult {
        let testingResult = TestingResult(
            testDestination: payload.testDestination,
            unfilteredResults: payload.testEntries.map { (testEntry: TestEntry) -> TestEntryResult in
                TestEntryResult.withResults(
                    testEntry: testEntry,
                    testRunResults: [
                        TestRunResult(
                            succeeded: false,
                            exceptions: [
                                TestException(
                                    reason: "Android tests are not supported by iOS worker",
                                    filePathInProject: "Unknown",
                                    lineNumber: 0,
                                    relatedTestName: testEntry.testName
                                )
                            ],
                            logs: [],
                            duration: 0,
                            startTime: dateProvider.dateSince1970ReferenceDate(),
                            hostName: LocalHostDeterminer.currentHostAddress,
                            simulatorId: "n/a"
                        )
                    ]
                )
            }
        )
        
        return BucketResult.testingResult(testingResult)
    }
}
