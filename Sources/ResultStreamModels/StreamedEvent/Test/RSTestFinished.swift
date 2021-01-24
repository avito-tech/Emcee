import Foundation

public class RSTestFinished: RSAbstractStreamedEvent<RSTestFinishedEventPayload> {
    public class override var name: RSString { "testFinished" }
}
