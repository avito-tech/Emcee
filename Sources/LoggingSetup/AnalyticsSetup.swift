import Foundation
import Graphite
import LocalHostDeterminer
import Logging
import Metrics
import QueueModels
import Sentry
import Statsd

extension MetricRecorderImpl {
    public convenience init(analyticsConfiguration: AnalyticsConfiguration) throws {
        let graphiteMetricHandler: GraphiteMetricHandler
        if let graphiteConfiguration = analyticsConfiguration.graphiteConfiguration {
            graphiteMetricHandler = try GraphiteMetricHandlerImpl(
                graphiteDomain: graphiteConfiguration.metricPrefix.components(separatedBy: "."),
                graphiteSocketAddress: graphiteConfiguration.socketAddress
            )
        } else {
            graphiteMetricHandler = NoOpMetricHandler()
        }
        
        let statsdMetricHandler: StatsdMetricHandler
        if let statsdConfiguration = analyticsConfiguration.statsdConfiguration {
            statsdMetricHandler = try StatsdMetricHandlerImpl(
                statsdDomain: statsdConfiguration.metricPrefix.components(separatedBy: "."),
                statsdClient: StatsdClientImpl(statsdSocketAddress: statsdConfiguration.socketAddress)
            )
        } else {
            statsdMetricHandler = NoOpMetricHandler()
        }
        
        self.init(
            graphiteMetricHandler: graphiteMetricHandler,
            statsdMetricHandler: statsdMetricHandler
        )
    }
}

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
