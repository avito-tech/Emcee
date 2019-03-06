import Foundation

public struct FbXcTestEventPair {
    public let startEvent: FbXcTestStartedEvent
    public let finishEvent: FbXcTestFinishedEvent?
    
    public init(startEvent: FbXcTestStartedEvent, finishEvent: FbXcTestFinishedEvent?) {
        self.startEvent = startEvent
        self.finishEvent = finishEvent
    }
}
