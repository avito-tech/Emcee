import Foundation

public class RSTestSuiteStarted: RSAbstractStreamedEvent<RSTestEventPayload<ActionTestSummaryGroup>> {
    public class override var name: RSString { "testSuiteStarted" }
}
