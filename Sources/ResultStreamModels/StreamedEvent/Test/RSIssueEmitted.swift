import Foundation

public class RSIssueEmitted: RSAbstractStreamedEvent<RSIssueEmittedEventPayload> {
    public class override var name: RSString { "issueEmitted" }
}
