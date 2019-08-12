import Foundation

/// Counter values are provided via args, e.g. ["cats": 10]
public final class CounterEvent: ChromeTraceEvent {
    public init(
        category: String,
        name: String,
        timestamp: EventTime,
        processId: String,
        threadId: String,
        args: [String: EventArgumentValue],
        color: ColorName? = nil
    ) {
        super.init(
            category: category,
            name: name,
            timestamp: timestamp,
            phase: .counter,
            processId: processId,
            threadId: threadId,
            args: args,
            color: color
        )
    }
}
