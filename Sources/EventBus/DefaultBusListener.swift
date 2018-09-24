import Foundation
import Models

open class DefaultBusListener: EventStream {
    
    public init() {}
    
    public func process(event: BusEvent) {
        switch event {
        case .didObtainTestingResult(let testingResult):
            didObtain(testingResult: testingResult)
        case .tearDown:
            tearDown()
        }
    }
    
    /// Called when a `TestingResult` has been obtained for a corresponding `Bucket`.
    open func didObtain(testingResult: TestingResult) {}
    
    /// Called when listener should tear down
    open func tearDown() {}
}
