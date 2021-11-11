import Foundation
import QueueModelsTestHelpers
import RunnerTestHelpers
import ScheduleStrategy
import TestHelpers
import XCTest

final class FixedBucketSizeSplitterTest: XCTestCase {
    func test___splitting() {
        let testEntryConfigurations = createTestEntryConfigurations(count: 12)
        
        let splitter = FixedBucketSizeSplitter(size: 5)
        
        let result = splitter.split(
            testEntryConfigurations: testEntryConfigurations,
            bucketSplitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1)
        )
        
        assert {
            result
        } equals: {
            [
                Array(testEntryConfigurations[0...4]),
                Array(testEntryConfigurations[5...9]),
                Array(testEntryConfigurations[10...11]),
            ]
        }
    }
}
