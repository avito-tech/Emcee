import Ansi
import Dispatch
import Foundation
import LocalHostDeterminer
import Logging
import Metrics
import Models
import PathLib
import Sentry
import TemporaryStuff

public final class LoggingSetup {
    private init() {}
    
    public static func setupLogging(stderrVerbosity: Verbosity) throws {
        let filename = "pid_\(ProcessInfo.processInfo.processIdentifier)"
        let detailedLogPath = try TemporaryFile(
            containerPath: try logsContainerFolder(),
            prefix: filename,
            suffix: ".log",
            deleteOnDealloc: false
        )
        
        let aggregatedHandler = AggregatedLoggerHandler(
            handlers: createLoggerHandlers(
                stderrVerbosity: stderrVerbosity,
                detaildLogFileHandle: detailedLogPath.fileHandleForWriting
            )
        )
        GlobalLoggerConfig.loggerHandler = aggregatedHandler
        Logger.always("Logging verbosity level is set to \(stderrVerbosity.stringCode)")
        Logger.always("To fetch detailed verbose log:")
        Logger.always("$ scp \(NSUserName())@\(LocalHostDeterminer.currentHostAddress):\(detailedLogPath.absolutePath) /tmp/\(filename).log && open /tmp/\(filename).log")
    }
    
    public static func setupAnalytics(analyticsConfiguration: AnalyticsConfiguration, emceeVersion: Version) throws {
        if let sentryConfiguration = analyticsConfiguration.sentryConfiguration {
            try setupSentry(emceeVersion: emceeVersion, sentryConfiguration: sentryConfiguration)
        }
        if let graphiteConfiguration = analyticsConfiguration.graphiteConfiguration {
            try setupGraphite(graphiteConfiguration: graphiteConfiguration)
        }
    }
    
    private static func setupSentry(emceeVersion: Version, sentryConfiguration: SentryConfiguration) throws {
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
    
    public static func tearDown() {
        let tearDownTimeout: TimeInterval = 10
        GlobalLoggerConfig.loggerHandler.tearDownLogging(timeout: tearDownTimeout)
        GlobalMetricConfig.metricHandler.tearDown(timeout: tearDownTimeout)
    }
    
    private static func createLoggerHandlers(
        stderrVerbosity: Verbosity,
        detaildLogFileHandle: FileHandle)
        -> [LoggerHandler]
    {
        return [
            createStderrInfoLoggerHandler(verbosity: stderrVerbosity),
            createDetailedLoggerHandler(fileHandle: detaildLogFileHandle)
        ]
    }
    
    private static func createStderrInfoLoggerHandler(verbosity: Verbosity) -> LoggerHandler {
        return FileHandleLoggerHandler(
            fileHandle: FileHandle.standardError,
            verbosity: verbosity,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            supportsAnsiColors: true,
            fileHandleShouldBeClosed: false
        )
    }
    
    private static func createDetailedLoggerHandler(fileHandle: FileHandle) -> LoggerHandler {
        return FileHandleLoggerHandler(
            fileHandle: fileHandle,
            verbosity: Verbosity.verboseDebug,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            supportsAnsiColors: false,
            fileHandleShouldBeClosed: true
        )
    }
    
    private static func createSentryLoggerHandler(
        emceeVersion: Version,
        sentryConfiguration: SentryConfiguration,
        verbosity: Verbosity
        ) throws -> LoggerHandler
    {
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
        ) throws -> MetricHandler
    {
        return try GraphiteMetricHandler(
            graphiteDomain: graphiteConfiguration.metricPrefix.components(separatedBy: "."),
            graphiteSocketAddress: graphiteConfiguration.socketAddress
        )
    }
    
    private static func logsContainerFolder() throws -> AbsolutePath {
        let libraryUrl = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let container = AbsolutePath(libraryUrl.path)
            .appending(components: ["Logs", "ru.avito.emcee.logs", ProcessInfo.processInfo.processName])
        try FileManager.default.createDirectory(atPath: container)
        return container
    }
}
