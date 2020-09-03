import Foundation
import IO
import Logging
import Metrics
import SocketModels
import Network

@available(OSX 10.14, *)
public final class StatsdMetricHandlerImpl: StatsdMetricHandler {
    struct InvalidPortValue: Error, CustomStringConvertible {
        let value: Int
        var description: String {
            return "Invalid port value \(value)"
        }
    }
    
    private let statsdDomain: [String]
    private let connection: NWConnection
    private let queue = DispatchQueue(label: "ru.avito.emcee.StatsdMetricHandlerImpl.serialQueue")
    
    private var metricsBuffer: [StatsdMetric] = []
    
    public init(
        statsdDomain: [String],
        statsdSocketAddress: SocketAddress
    ) throws {
        guard let port = NWEndpoint.Port(rawValue: UInt16(statsdSocketAddress.port.value)) else {
            throw InvalidPortValue(value: statsdSocketAddress.port.value)
        }
        
        self.statsdDomain = statsdDomain
        self.connection = NWConnection(
            host: .name(statsdSocketAddress.host, nil),
            port: port,
            using: .udp
        )
        
        connection.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .setup:
                Logger.info("Setting up statsd connection")
            case .waiting(let error):
                Logger.warning("Statsd connection waiting: \(error.debugDescription)")
            case .preparing:
                Logger.info("Preparing statsd connection")
            case .ready:
                Logger.info("Connected to statsd endpoint")
                self.metricsBuffer.forEach(self.send)
                self.metricsBuffer.removeAll()
            case .failed(let error):
                Logger.error("Statsd connection failed: \(error.debugDescription)")
                self.connection.cancel()
            case .cancelled:
                Logger.warning("Statsd connection was cancelled")
                if !self.metricsBuffer.isEmpty {
                    Logger.warning("Metrics buffer wasn't empty when connection was cancelled: \(self.metricsBuffer)")
                }
            @unknown default:
                Logger.warning("Unknown statsd connection state: \(state)")
            }
        }
        connection.start(queue: queue)
    }
    
    public func handle(metric: StatsdMetric) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let state = self.connection.state
            switch state {
            case .cancelled, .failed:
                Logger.warning("Statsd connection is \(state), metric \(metric) is dropped")
            case .waiting, .preparing, .setup:
                Logger.warning("Buffering metric \(metric)")
                self.metricsBuffer.append(metric)
            case .ready:
                self.send(metric: metric)
            @unknown default:
                Logger.warning("Unknown statsd connection state: \(state)")
            }
        }
    }
    
    public func tearDown(timeout: TimeInterval) {
        queue.async { [connection] in
            connection.cancel()
        }
    }
    
    private func send(metric: StatsdMetric) {
        connection.send(
            content: Data(metric.build(domain: statsdDomain).utf8),
            completion: NWConnection.SendCompletion.contentProcessed {
                if let error = $0 {
                    Logger.error("Statsd metric send failed: \(error.debugDescription)")
                }
            }
        )
    }
}
