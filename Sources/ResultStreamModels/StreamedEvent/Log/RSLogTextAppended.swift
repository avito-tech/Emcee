import Foundation

public class RSLogTextAppended: RSAbstractStreamedEvent<RSLogTextAppendedEventPayload> {
    public class override var name: RSString { "logTextAppended" }
}
