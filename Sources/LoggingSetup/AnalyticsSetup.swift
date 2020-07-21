import Foundation
import LocalHostDeterminer
import Logging
import Metrics
import QueueModels
import Sentry

public final class AnalyticsSetup {
    private init() {}
    
    public static func setupAnalytics(analyticsConfiguration: AnalyticsConfiguration, emceeVersion: Version) throws {
        if let sentryConfiguration = analyticsConfiguration.sentryConfiguration {
            try setupSentry(emceeVersion: emceeVersion, sentryConfiguration: sentryConfiguration)
        }
        if let graphiteConfiguration = analyticsConfiguration.graphiteConfiguration {
            try setupGraphite(graphiteConfiguration: graphiteConfiguration)
        }
    }
    
    public static func tearDown(timeout: TimeInterval) {
        GlobalMetricConfig.metricHandler.tearDown(timeout: timeout)
    }
    
    private static func setupSentry(
        emceeVersion: Version,
        sentryConfiguration: SentryConfiguration
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

    private static func setupGraphite(graphiteConfiguration: GraphiteConfiguration) throws {
        GlobalMetricConfig.metricHandler = try createGraphiteMetricHandler(
            graphiteConfiguration: graphiteConfiguration
        )
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
    
    private static func createGraphiteMetricHandler(
        graphiteConfiguration: GraphiteConfiguration
    ) throws -> MetricHandler {
        return try GraphiteMetricHandler(
            graphiteDomain: graphiteConfiguration.metricPrefix.components(separatedBy: "."),
            graphiteSocketAddress: graphiteConfiguration.socketAddress
        )
    }
}
