import Foundation

public final class MetricRecorder {
    private init() {}
    
    public static func capture(_ metric: Metric) {
        GlobalMetricConfig.metricHandler.handle(metric: metric)
    }
}
