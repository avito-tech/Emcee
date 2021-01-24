import Foundation

public class RSTestStarted: RSAbstractStreamedEvent<RSTestEventPayload<RSActionTestSummaryIdentifiableObject>> {
    public class override var name: RSString { "testStarted" }
}
