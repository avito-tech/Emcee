import MetricsExtensions

public protocol RunnerProvider {
    func create(
        specificMetricRecorder: SpecificMetricRecorder
    ) -> Runner
}
