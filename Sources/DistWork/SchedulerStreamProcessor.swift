import Foundation
import Models
import Scheduler

public final class SchedulerStreamProcessor: SchedulerStream {
    
    public typealias OnReceiveTestingResult = (TestingResult) -> Void
    
    private let onReceiveTestingResult: OnReceiveTestingResult

    public init(onReceiveTestingResultForBucket: @escaping OnReceiveTestingResult) {
        self.onReceiveTestingResult = onReceiveTestingResultForBucket
    }
    
    // MARK: - Stream API
    
    public func scheduler(_ sender: Scheduler, didReceiveTestingResult testingResult: TestingResult) {
        onReceiveTestingResult(testingResult)
    }
}
