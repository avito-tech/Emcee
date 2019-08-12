import Foundation

public final class CompleteEvent: ChromeTraceEvent {
    public let duration: EventTime

    private enum CodingKeys: String, CodingKey {
        case duration = "dur"
    }

    public init(
        category: String,
        name: String,
        timestamp: EventTime,
        duration: EventTime,
        processId: String,
        threadId: String,
        args: [String: EventArgumentValue]? = nil,
        color: ColorName? = nil
    ) {
        self.duration = duration
        super.init(
            category: category,
            name: name,
            timestamp: timestamp,
            phase: .complete,
            processId: processId,
            threadId: threadId,
            args: args
        )
    }
}
