import Foundation

public class RSLogSectionAttached: RSAbstractStreamedEvent<RSLogSectionAttachedEventPayload> {
    public class override var name: RSString { "logSectionAttached" }
}
