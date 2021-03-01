import Foundation
import LocalHostDeterminer
import EmceeLogging
import QueueModels
import Sentry

public final class AnalyticsSetup {
    private init() {}
    
    public static func setupSentry(
        sentryConfiguration: SentryConfiguration,
        emceeVersion: Version
    ) throws {
        let loggerHandler = AggregatedLoggerHandler(
            handlers: [
                GlobalLoggerConfig.loggerHandler,
                try createSentryLoggerHandler(
                    emceeVersion: emceeVersion,
                    sentryConfiguration: sentryConfiguration,
                    verbosity: .error
                )
            ]
        )
        GlobalLoggerConfig.loggerHandler = loggerHandler
    }
    
    private static func createSentryLoggerHandler(
        emceeVersion: Version,
        sentryConfiguration: SentryConfiguration,
        verbosity: Verbosity
    ) throws -> LoggerHandler {
        let dsn = try DSN.create(dsnUrl: sentryConfiguration.dsn)
        return SentryLoggerHandler(
            dsn: dsn,
            hostname: LocalHostDeterminer.currentHostAddress,
            release: emceeVersion.value,
            sentryEventDateFormatter: SentryDateFormatterFactory.createDateFormatter(),
            urlSession: URLSession.shared,
            verbosity: verbosity
        )
    }
}
