import EventBus
import Foundation
import Models
import Scheduler

public final class EventStreamProcessor: EventStream {
    
    public typealias OnReceiveTestingResult = (TestingResult) -> Void
    
    private let onReceiveTestingResult: OnReceiveTestingResult

    public init(onReceiveTestingResultForBucket: @escaping OnReceiveTestingResult) {
        self.onReceiveTestingResult = onReceiveTestingResultForBucket
    }
    
    // MARK: - Stream API
    
    public func didObtain(testingResult: TestingResult) {
        onReceiveTestingResult(testingResult)
    }
    
    public func tearDown() {
        
    }
}
