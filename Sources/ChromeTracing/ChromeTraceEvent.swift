import Foundation

open class ChromeTraceEvent: Encodable {
    public let category: String
    public let name: String
    public let timestamp: EventTime
    public let phase: Phase
    public let processId: String
    public let threadId: String
    public let args: [String: EventArgumentValue]?
    public let color: ColorName?

    private enum CodingKeys: String, CodingKey {
        case category = "cat"
        case name = "name"
        case timestamp = "ts"
        case phase = "ph"
        case processId = "pid"
        case threadId = "tid"
        case args = "args"
        case color = "cname"
    }

    public init(
        category: String,
        name: String,
        timestamp: EventTime,
        phase: Phase,
        processId: String,
        threadId: String,
        args: [String: EventArgumentValue]? = nil,
        color: ColorName? = nil
    ) {
        self.category = category
        self.name = name
        self.timestamp = timestamp
        self.phase = phase
        self.processId = processId
        self.threadId = threadId
        self.args = args
        self.color = color
    }
}
