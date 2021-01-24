import Foundation

public class RSLogMessageEmitted: RSAbstractStreamedEvent<RSLogMessageEmittedEventPayload> {
    public class override var name: RSString { "logMessageEmitted" }
}
