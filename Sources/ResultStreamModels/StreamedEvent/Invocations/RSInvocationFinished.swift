import Foundation

public class RSInvocationFinished: RSAbstractStreamedEvent<RSInvocationFinishedEventPayload> {
    public class override var name: RSString { "invocationFinished" }
}
