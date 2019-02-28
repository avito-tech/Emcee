import Foundation

public final class SentryConfiguration: Codable, Equatable {
    public let dsn: URL

    public init(dsn: URL) {
        self.dsn = dsn
    }

    public static func ==(left: SentryConfiguration, right: SentryConfiguration) -> Bool {
        return left.dsn == right.dsn
    }
}
