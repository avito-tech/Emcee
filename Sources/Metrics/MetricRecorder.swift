import Foundation
import Graphite
import Statsd

public final class MetricRecorder {
    private init() {}
    
    public static func capture(_ metric: GraphiteMetric) {
        GlobalMetricConfig.graphiteMetricHandler.handle(metric: metric)
    }
    
    public static func capture(_ metric: StatsdMetric) {
        GlobalMetricConfig.statsdMetricHandler.handle(metric: metric)
    }
    
    public static func capture(_ metrics: [GraphiteMetric]) {
        metrics.forEach(capture)
    }
    
    public static func capture(_ metrics: [StatsdMetric]) {
        metrics.forEach(capture)
    }
    
    public static func capture(_ metrics: GraphiteMetric...) {
        capture(metrics)
    }
    
    public static func capture(_ metrics: StatsdMetric...) {
        capture(metrics)
    }
}
