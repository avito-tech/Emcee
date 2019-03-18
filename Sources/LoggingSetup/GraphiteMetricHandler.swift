import Foundation
import Graphite
import Logging
import Metrics
import Models
import IO

public final class GraphiteMetricHandler: MetricHandler {
    private let graphiteDomain: [String]
    private let outputStream: EasyOutputStream
    private let graphiteClient: GraphiteClient
    
    public init(
        graphiteDomain: [String],
        graphiteSocketAddress: SocketAddress
        ) throws
    {
        self.graphiteDomain = graphiteDomain
        outputStream = EasyOutputStream(
            outputStreamProvider: NetworkSocketOutputStreamProvider(
                host: graphiteSocketAddress.host,
                port: graphiteSocketAddress.port
            ),
            errorHandler: { stream, error in
                Logger.error("Graphite stream error: \(error)")
                GraphiteMetricHandler.attemptToReopenStream(stream: stream)
            },
            streamEndHandler: { stream in
                Logger.warning("Graphite stream has been closed")
                GraphiteMetricHandler.attemptToReopenStream(stream: stream)
            }
        )
        try outputStream.open()
        self.graphiteClient = GraphiteClient(easyOutputStream: outputStream)
    }
    
    public func handle(metric: Metric) {
        do {
            try graphiteClient.send(
                path: graphiteDomain + metric.components,
                value: metric.value,
                timestamp: metric.timestamp
            )
        } catch {
            Logger.warning("Failed to send metric \(metric) to graphite: \(error)")
        }
    }
    
    public func tearDown(timeout: TimeInterval) {
        let result = outputStream.waitAndClose(timeout: timeout)
        if result == .flushTimeout {
            Logger.warning("Failed to tear down in time")
        }
    }
    
    // MARK: - Tracking stream reopens
    
    private static var numberOfAttemptsToReopenStream = 0
    private static let maximumAttemptsToReopenStream = 10
    
    private static func shouldAttemptToReopenStream() -> Bool {
        numberOfAttemptsToReopenStream += 1
        return numberOfAttemptsToReopenStream < maximumAttemptsToReopenStream
    }
    
    private static func attemptToReopenStream(stream: EasyOutputStream) {
        do {
            if GraphiteMetricHandler.shouldAttemptToReopenStream() {
                stream.close()
                try stream.open()
            } else {
                Logger.warning("Exceeded number of attempts to reopen stream to graphite.")
                stream.close()
            }
        } catch {
            Logger.warning("Error re-opening previously closed stream to Graphite: \(error)")
        }
    }
}
