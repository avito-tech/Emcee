import Foundation
import GraphiteClient
import IO
import Logging
import Metrics
import SocketModels

public final class GraphiteMetricHandlerImpl: GraphiteMetricHandler {
    private let graphiteDomain: [String]
    private let outputStream: EasyOutputStream
    private let graphiteClient: GraphiteClient
    
    public init(
        graphiteDomain: [String],
        graphiteSocketAddress: SocketAddress
    ) throws {
        self.graphiteDomain = graphiteDomain
        
        let streamReopener = StreamReopener(maximumAttemptsToReopenStream: 10)
        
        outputStream = EasyOutputStream(
            outputStreamProvider: NetworkSocketOutputStreamProvider(
                host: graphiteSocketAddress.host,
                port: graphiteSocketAddress.port.value
            ),
            errorHandler: { stream, error in
                Logger.error("Graphite stream error: \(error)")
                streamReopener.attemptToReopenStream(stream: stream)
            },
            streamEndHandler: { stream in
                Logger.warning("Graphite stream has been closed")
                streamReopener.attemptToReopenStream(stream: stream)
            }
        )
        
        streamReopener.streamHasBeenOpened()
        try outputStream.open()
        self.graphiteClient = GraphiteClient(easyOutputStream: outputStream)
    }
    
    public func handle(metric: Metrics.GraphiteMetric) {
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
}
