import Graphite
import Statsd

public protocol MutableMetricRecorder: MetricRecorder {
    func setGraphiteMetric(handler: GraphiteMetricHandler)
    func setStatsdMetric(handler: StatsdMetricHandler)
}
