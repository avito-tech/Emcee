import Foundation
import Metrics
import Models
import Timer
import WorkerAlivenessModels
import WorkerAlivenessProvider

public final class WorkerAlivenessMatricCapturer {
    private let timer: DispatchBasedTimer
    private let workerAlivenessProvider: WorkerAlivenessProvider

    public init(
        reportInterval: DispatchTimeInterval,
        workerAlivenessProvider: WorkerAlivenessProvider
    ) {
        self.timer = DispatchBasedTimer(repeating: reportInterval, leeway: .seconds(1))
        self.workerAlivenessProvider = workerAlivenessProvider
    }
    
    public func start() {
        timer.start { [weak workerAlivenessProvider] timer in
            guard let aliveness = workerAlivenessProvider?.workerAliveness else {
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
                status: $0.value.metricComponentName
            )
        }
        MetricRecorder.capture(metrics)
    }
}

private extension WorkerAliveness {
    var metricComponentName: String {
        if !registered { return "notRegistered" }
        if disabled { return "disabled" }
        if silent {
            return "silent"
        } else {
            return "alive"
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
