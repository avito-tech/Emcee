import DateProvider
import Foundation
import Metrics
import MetricsExtensions
import QueueModels
import Timer
import WorkerAlivenessModels
import WorkerAlivenessProvider

public final class WorkerAlivenessMetricCapturer {
    private let dateProvider: DateProvider
    private let timer: DispatchBasedTimer
    private let queueHostname: String
    private let version: Version
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let globalMetricRecorder: GlobalMetricRecorder

    public init(
        dateProvider: DateProvider,
        reportInterval: DispatchTimeInterval,
        queueHostname: String,
        version: Version,
        workerAlivenessProvider: WorkerAlivenessProvider,
        globalMetricRecorder: GlobalMetricRecorder
    ) {
        self.dateProvider = dateProvider
        self.timer = DispatchBasedTimer(repeating: reportInterval, leeway: .seconds(1))
        self.queueHostname = queueHostname
        self.version = version
        self.workerAlivenessProvider = workerAlivenessProvider
        self.globalMetricRecorder = globalMetricRecorder
    }
    
    public func start() {
        timer.start { [weak self] timer in
            guard let strongSelf = self else {
                return timer.stop()
            }
            let aliveness = strongSelf.workerAlivenessProvider.workerAliveness
            strongSelf.captureMetrics(aliveness: aliveness)
        }
    }
    
    public func stop() {
        timer.stop()
    }
    
    private func captureMetrics(
        aliveness: [WorkerId: WorkerAliveness]
    ) {
        let metrics: [WorkerStatusMetric] = aliveness.map {
            WorkerStatusMetric(
                workerId: $0.key,
                status: $0.value.metricComponentName,
                version: version,
                queueHost: queueHostname,
                timestamp: dateProvider.currentDate()
            )
        }
        globalMetricRecorder.capture(metrics)
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
