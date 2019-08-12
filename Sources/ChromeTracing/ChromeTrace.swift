import Foundation

public final class ChromeTrace: Encodable {
    public let traceEvents: [ChromeTraceEvent]

    public init(traceEvents: [ChromeTraceEvent]) {
        self.traceEvents = traceEvents
    }
}
