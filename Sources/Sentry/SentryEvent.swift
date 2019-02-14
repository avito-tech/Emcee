import Foundation

public final class SentryEvent {    
    public let eventId: String
    public let platform = "cocoa"
    public let message: String
    public let timestamp: Date
    public let level: SentryErrorLevel
    public let release: String
    public let extra: [String: Any]
    public let sdk = [
        "name": SentryClientVersion.clientName,
        "version": SentryClientVersion.clientVersion
    ]
    
    public init(
        eventId: String = SentryEvent.generateEventId(),
        message: String,
        timestamp: Date,
        level: SentryErrorLevel,
        release: String,
        extra: [String: Any])
    {
        self.eventId = eventId
        self.message = message
        self.timestamp = timestamp
        self.level = level
        self.release = release
        self.extra = extra
    }
    
    public func dictionaryRepresentation(dateFormatter: DateFormatter) -> [String: Any] {
        let attributes: [String: Any] = [
            "event_id": eventId,
            "message": message,
            "timestamp": dateFormatter.string(from: timestamp),
            "level": level.rawValue,
            "platform": platform,
            "sdk": sdk,
            "extra": extra,
            "release": release,
        ]
        return attributes
    }
    
    public static func generateEventId() -> String {
        return UUID().uuidString.replacingOccurrences(of: "-", with: "")
    }
}
