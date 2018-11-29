import Foundation
import Models

public final class BucketQueueAcceptResult {
    // Not every result is ready to collect,
    // this may be due to retrying
    public let testingResultToCollect: TestingResult
    
    public init(testingResultToCollect: TestingResult) {
        self.testingResultToCollect = testingResultToCollect
    }
}
