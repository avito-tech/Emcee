public final class ExpectationAwaitingError: Error, CustomStringConvertible {
    public var description: String {
        return "Awaiting for result failed"
    }
}
