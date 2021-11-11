import Foundation
import UniqueIdentifierGenerator

public struct ScheduleStrategy: Codable, Hashable {
    private let testSplitterType: TestSplitterType
    
    public var testSplitter: TestSplitter {
        switch testSplitterType {
        case .individual:
            return IndividualBucketSplitter()
        case .equallyDivided:
            return EquallyDividedBucketSplitter()
        case .progressive:
            return ProgressiveBucketSplitter()
        case .unsplit:
            return UnsplitBucketSplitter()
        case .fixedBucketSize(let size):
            return FixedBucketSizeSplitter(size: size)
        }
    }
    
    public init(
        testSplitterType: TestSplitterType
    ) {
        self.testSplitterType = testSplitterType
    }
}
