import Foundation

public class RSInvocationStarted: RSAbstractStreamedEvent<RSInvocationStartedEventPayload> {
    public class override var name: RSString { "invocationStarted" }
}
