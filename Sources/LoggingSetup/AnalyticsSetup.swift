import Foundation
import Graphite
import LocalHostDeterminer
import Logging
import Metrics
import QueueModels
import Sentry
import Statsd

public final class AnalyticsSetup {
    private init() {}
    
    public static func setupAnalytics(analyticsConfiguration: AnalyticsConfiguration, emceeVersion: Version) throws {
        if let sentryConfiguration = analyticsConfiguration.sentryConfiguration {
            try setupSentry(emceeVersion: emceeVersion, sentryConfiguration: sentryConfiguration)
        }
        if let graphiteConfiguration = analyticsConfiguration.graphiteConfiguration {
            try setupGraphite(configuration: graphiteConfiguration)
        }
        if let statsdConfiguration = analyticsConfiguration.statsdConfiguration {
            try setupStatsd(configuration: statsdConfiguration)
        }
    }
    
    public static func tearDown(timeout: TimeInterval) {
        GlobalMetricConfig.graphiteMetricHandler.tearDown(timeout: timeout)
        GlobalMetricConfig.statsdMetricHandler.tearDown(timeout: timeout)
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

    private static func setupGraphite(configuration: MetricConfiguration) throws {
        GlobalMetricConfig.graphiteMetricHandler = try createGraphiteMetricHandler(
            configuration: configuration
        )
    }
    
    private static func setupStatsd(configuration: MetricConfiguration) throws {
        GlobalMetricConfig.statsdMetricHandler = try createStatsdMetricHandler(
            configuration: configuration
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
        configuration: MetricConfiguration
    ) throws -> GraphiteMetricHandler {
        return try GraphiteMetricHandlerImpl(
            graphiteDomain: configuration.metricPrefix.components(separatedBy: "."),
            graphiteSocketAddress: configuration.socketAddress
        )
    }
    
    private static func createStatsdMetricHandler(
        configuration: MetricConfiguration
    ) throws -> StatsdMetricHandler {
        return try StatsdMetricHandlerImpl(
            statsdDomain: configuration.metricPrefix.components(separatedBy: "."),
            statsdClient: StatsdClientImpl(statsdSocketAddress: configuration.socketAddress)
        )
    }
}
