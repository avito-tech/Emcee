import Foundation

public class RSTestSuiteFinished: RSAbstractStreamedEvent<RSTestEventPayload<ActionTestSummaryGroup>> {
    public class override var name: RSString { "testSuiteFinished" }
}
