import Foundation

public final class InstantEvent: ChromeTraceEvent {
    public let scope: Scope

    public enum Scope: String, Encodable {
        /// will draw instant event time from the top to the bottom of the timeline
        case global = "g"

        /// will draw instant event time through all threads of a given process
        case process = "p"

        /// will draw instant event time of a single thread
        case thread = "t"
    }

    private enum CodingKeys: String, CodingKey {
        case scope = "s"
    }

    public init(
        category: String,
        name: String,
        timestamp: EventTime,
        scope: Scope = .thread,
        processId: String,
        threadId: String,
        args: [String: EventArgumentValue]? = nil,
        color: ColorName? = nil
    ) {
        self.scope = scope
        super.init(
            category: category,
            name: name,
            timestamp: timestamp,
            phase: .instant,
            processId: processId,
            threadId: threadId,
            args: args,
            color: color
        )
    }
}
