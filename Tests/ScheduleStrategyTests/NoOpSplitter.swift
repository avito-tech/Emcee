@testable import ScheduleStrategy
import Foundation
import Models

public final class DirectSplitter: BucketSplitter {
    
    public init() {
        super.init(description: "Noop schedule strategy")
    }
    
    public override func split(inputs: [TestEntryConfiguration], bucketSplitInfo: BucketSplitInfo) -> [[TestEntryConfiguration]] {
        return [inputs]
    }
}
