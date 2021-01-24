import Foundation

public class RSLogSectionClosed: RSAbstractStreamedEvent<RSLogSectionClosedEventPayload> {
    public class override var name: RSString { "logSectionClosed" }
}
