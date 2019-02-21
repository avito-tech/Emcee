import Foundation
import Logging
import Models
import Sentry

public final class SentryLoggerHandler: LoggerHandler {
    private let dsn: DSN
    private let group = DispatchGroup()
    private let hostname: String
    private let release: String
    private let sentryEventDateFormatter: DateFormatter
    private let urlSession: URLSession
    private let verbosity: Verbosity
    
    private typealias XSentryAuthHeader = (key: String, value: String)

    public init(
        dsn: DSN,
        hostname: String,
        release: String,
        sentryEventDateFormatter: DateFormatter,
        urlSession: URLSession,
        verbosity: Verbosity)
    {
        self.dsn = dsn
        self.hostname = hostname
        self.release = release
        self.sentryEventDateFormatter = sentryEventDateFormatter
        self.urlSession = urlSession
        self.verbosity = verbosity
    }
    
    public func handle(logEntry: LogEntry) {
        guard logEntry.verbosity <= verbosity else { return }
        
        let sentryEvent = SentryEvent(
            message: logEntry.message,
            timestamp: logEntry.timestamp,
            level: logEntry.verbosity.toSentryLevel(),
            release: release,
            extra: [
                "file": logEntry.file.description,
                "hostname": hostname,
                "line": logEntry.line,
                "verbosity": logEntry.verbosity.stringCode
            ]
        )
        
        let payload: Data
        do {
            payload = try JSONSerialization.data(
                withJSONObject: sentryEvent.dictionaryRepresentation(dateFormatter: sentryEventDateFormatter),
                options: []
            )
        } catch {
            return
        }

        let authHeader = buildAuthHeader(dsn: dsn)
        
        var request = URLRequest(url: dsn.storeUrl)
        request.setValue(authHeader.value, forHTTPHeaderField: authHeader.key)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "post"
        request.httpBody = payload
        request.timeoutInterval = 30
        
        let task = urlSession.dataTask(with: request) { [weak self] _,_,_ in
            self?.group.leave()
        }
        task.resume()
        group.enter()
    }
    
    public func tearDownLogging(timeout: TimeInterval) {
        _ = group.wait(timeout: .now() + timeout)
    }
    
    private func buildAuthHeader(dsn: DSN) -> XSentryAuthHeader {
        let headerParts: [(String, String)] = [
            ("Sentry sentry_version", String(SentryClientVersion.sentryVersion)),
            ("sentry_client", "\(SentryClientVersion.clientName)/\(SentryClientVersion.clientVersion)"),
            ("sentry_timestamp", String(Int64(Date().timeIntervalSince1970))),
            ("sentry_key", dsn.publicKey),
            ("sentry_secret", dsn.secretKey),
        ]
        
        let header = headerParts.reduce([], { result, header in
            var result = result
            result.append("\(header.0)=\(header.1)")
            return result
        }).joined(separator: ",")
        
        return ("X-Sentry-Auth", header)
    }
}

extension Verbosity {
    func toSentryLevel() -> SentryErrorLevel {
        switch self {
        case .verboseDebug:
            return .debug
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .fatal:
            return .fatal
        case .always:
            return .info
        }
    }
}
