import DateProvider
import Foundation
import LocalHostDeterminer
import Metrics
import MetricsExtensions
import QueueModels
import Timer
import WorkerAlivenessModels
import WorkerAlivenessProvider

public final class WorkerAlivenessMetricCapturer {
    private let dateProvider: DateProvider
    private let timer: DispatchBasedTimer
    private let version: Version
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let globalMetricRecorder: GlobalMetricRecorder

    public init(
        dateProvider: DateProvider,
        reportInterval: DispatchTimeInterval,
        version: Version,
        workerAlivenessProvider: WorkerAlivenessProvider,
        globalMetricRecorder: GlobalMetricRecorder
    ) {
        self.dateProvider = dateProvider
        self.timer = DispatchBasedTimer(repeating: reportInterval, leeway: .seconds(1))
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
                queueHost: LocalHostDeterminer.currentHostAddress,
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
