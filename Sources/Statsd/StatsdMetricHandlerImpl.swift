import Foundation
import IO
import Logging
import SocketModels
import Network

public final class StatsdMetricHandlerImpl: StatsdMetricHandler {
    private let statsdDomain: [String]
    private let statsdClient: StatsdClient
    private let serialQueue: DispatchQueue
    
    private var metricsBuffer: [StatsdMetric] = []
    
    public init(
        statsdDomain: [String],
        statsdClient: StatsdClient,
        serialQueue: DispatchQueue = DispatchQueue(label: "StatsdMetricHandlerImpl.serialQueue")
    ) throws {
        self.statsdDomain = statsdDomain
        self.statsdClient = statsdClient
        self.serialQueue = serialQueue
        
        self.statsdClient.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .setup:
                Logger.debug("Setting up statsd connection")
            case .waiting(let error):
                Logger.warning("Statsd connection waiting: \(error)")
            case .preparing:
                Logger.debug("Preparing statsd connection")
            case .ready:
                Logger.debug("Connected to statsd endpoint")
                self.metricsBuffer.forEach(self.send)
                self.metricsBuffer.removeAll()
            case .failed(let error):
                Logger.error("Statsd connection failed: \(error)")
                self.statsdClient.cancel()
            case .cancelled:
                Logger.warning("Statsd connection was cancelled")
                if !self.metricsBuffer.isEmpty {
                    Logger.warning("Metrics buffer wasn't empty when connection was cancelled: \(self.metricsBuffer)")
                }
            @unknown default:
                Logger.warning("Unknown statsd connection state: \(state)")
            }
        }
        statsdClient.start(queue: serialQueue)
    }
    
    public func handle(metric: StatsdMetric) {
        serialQueue.async { [weak self] in
            guard let self = self else { return }
            let state = self.statsdClient.state
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
        serialQueue.async { [statsdClient] in
            statsdClient.cancel()
        }
    }
    
    private func send(metric: StatsdMetric) {
        statsdClient.send(
            content: Data(metric.build(domain: statsdDomain).utf8)
        )
    }
}
