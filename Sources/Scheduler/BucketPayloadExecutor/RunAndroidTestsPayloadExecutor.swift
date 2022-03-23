import DateProvider
import CommonTestModels
import Foundation
import MetricsExtensions
import QueueModels

public final class RunAndroidTestsPayloadExecutor {
    private let dateProvider: DateProvider
    private let hostname: String
    
    public init(
        dateProvider: DateProvider,
        hostname: String
    ) {
        self.dateProvider = dateProvider
        self.hostname = hostname
    }
    
    public func execute(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketId: BucketId,
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
                                    reason: "Android tests are not supported by Apple worker",
                                    filePathInProject: "Unknown",
                                    lineNumber: 0,
                                    relatedTestName: testEntry.testName
                                )
                            ],
                            logs: [],
                            duration: 0,
                            startTime: dateProvider.dateSince1970ReferenceDate(),
                            hostName: hostname,
                            udid: "n/a"
                        )
                    ]
                )
            },
            xcresultData: []
        )
        
        return BucketResult.testingResult(testingResult)
    }
}
