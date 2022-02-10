import Foundation
import ScheduleStrategy
import TestHelpers
import XCTest

final class FixedBucketSizeSplitterTest: XCTestCase {
    func test___splitting() {
        let configuredTestEntries = createConfiguredTestEntries(count: 12)
        
        let splitter = FixedBucketSizeSplitter(size: 5)
        
        let result = splitter.split(
            configuredTestEntries: configuredTestEntries,
            bucketSplitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: 1)
        )
        
        assert {
            result
        } equals: {
            [
                Array(configuredTestEntries[0...4]),
                Array(configuredTestEntries[5...9]),
                Array(configuredTestEntries[10...11]),
            ]
        }
    }
}
