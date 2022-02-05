import Foundation

open class DefaultBusListener: EventStream {
    
    public init() {}
    
    open func process(event: BusEvent) {
        switch event {
        case .appleRunnerEvent(let runnerEvent):
            self.runnerEvent(runnerEvent)
        case .tearDown:
            tearDown()
        }
    }
    
    open func runnerEvent(_ event: AppleRunnerEvent) {}
    open func tearDown() {}
}
