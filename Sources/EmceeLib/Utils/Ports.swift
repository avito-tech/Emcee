import Models

public final class Ports {
    /// TCP ports that are expecred to be taken by the queue server.
    /// This port range appears to be unassigned according to IANA
    /// https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xhtml?&page=131
    public static let defaultQueuePortRange: ClosedRange<Port> = 41000...41010
}
