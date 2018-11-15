import Foundation
import Models

public final class TestingResultFixtures {
    public static func createTestingResult(unfilteredResults: [TestEntryResult] = []) -> TestingResult {
        return TestingResult(
            bucketId: "bucket_id",
            testDestination: TestDestinationFixtures.testDestination,
            unfilteredResults: unfilteredResults)
    }
}
