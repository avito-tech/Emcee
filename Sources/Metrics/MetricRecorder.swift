import Foundation

public final class MetricRecorder {
    private init() {}
    
    public static func capture(_ metric: Metric) {
        GlobalMetricConfig.metricHandler.handle(metric: metric)
    }
    
    public static func capture(_ metrics: Metric...) {
        for metric in metrics {
            capture(metric)
        }
    }
    
    public static func capture(_ contentsOf: [Metric]) {
        for metric in contentsOf {
            capture(metric)
        }
    }
}
