import EventBus
import Foundation
import Models
import Scheduler

public final class EventStreamProcessor: DefaultBusListener {
    
    public typealias OnReceiveTestingResult = (TestingResult) -> Void
    
    private let onReceiveTestingResult: OnReceiveTestingResult

    public init(onReceiveTestingResultForBucket: @escaping OnReceiveTestingResult) {
        self.onReceiveTestingResult = onReceiveTestingResultForBucket
    }
    
    public override func didObtain(testingResult: TestingResult) {
        onReceiveTestingResult(testingResult)
    }
}
