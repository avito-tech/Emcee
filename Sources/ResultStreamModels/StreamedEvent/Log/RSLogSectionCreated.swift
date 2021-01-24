import Foundation

public class RSLogSectionCreated: RSAbstractStreamedEvent<RSLogSectionCreatedEventPayload> {
    public class override var name: RSString { "logSectionCreated" }
}
