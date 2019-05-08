import Foundation
import Models

open class DefaultBusListener: EventStream {
    
    public init() {}
    
    open func process(event: BusEvent) {
        switch event {
        case .didObtainTestingResult(let testingResult):
            didObtain(testingResult: testingResult)
        case .runnerEvent(let runnerEvent):
            self.runnerEvent(runnerEvent)
        case .tearDown:
            tearDown()
        }
    }
    
    open func didObtain(testingResult: TestingResult) {}
    open func runnerEvent(_ event: RunnerEvent) {}
    open func tearDown() {}
}
