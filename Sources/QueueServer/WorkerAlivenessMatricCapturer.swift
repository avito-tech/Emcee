import Foundation
import Metrics
import Models
import Timer
import WorkerAlivenessTracker

public final class WorkerAlivenessMatricCapturer {
    private let timer: DispatchBasedTimer
    private let workerAlivenessTracker: WorkerAlivenessTracker

    public init(
        reportInterval: DispatchTimeInterval,
        workerAlivenessTracker: WorkerAlivenessTracker
    ) {
        self.timer = DispatchBasedTimer(repeating: reportInterval, leeway: .seconds(1))
        self.workerAlivenessTracker = workerAlivenessTracker
    }
    
    public func start() {
        timer.start { [weak workerAlivenessTracker] timer in
            guard let aliveness = workerAlivenessTracker?.workerAliveness else {
                return timer.stop()
            }
            WorkerAlivenessMatricCapturer.captureMetrics(aliveness: aliveness)
        }
    }
    
    public func stop() {
        timer.stop()
    }
    
    private static func captureMetrics(
        aliveness: [WorkerId: WorkerAliveness]
    ) {
        let metrics: [WorkerStatusMetric] = aliveness.map {
            WorkerStatusMetric(
                workerId: $0.key.value,
                status: $0.value.status.metricComponentName
            )
        }
        MetricRecorder.capture(metrics)
    }
}

private extension WorkerAliveness.Status {
    var metricComponentName: String {
        switch self {
        case .alive: return "alive"
        case .blocked: return "blocked"
        case .notRegistered: return "notRegistered"
        case .silent: return "silent"
        }
    }
}

public final class WorkerStatusMetric: Metric {
    public init(workerId: String, status: String) {
        super.init(
            fixedComponents: [
                "queue",
                "worker",
                "status",
            ],
            variableComponents: [
                workerId,
                status,
                Metric.reservedField,
                Metric.reservedField,
            ],
            value: 1.0,
            timestamp: Date()
        )
    }
}
