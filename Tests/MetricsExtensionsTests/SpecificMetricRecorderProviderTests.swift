import Graphite
import MetricsRecording
import MetricsExtensions
import SocketModels
import Statsd
import TestHelpers
import XCTest

final class SpecificMetricRecorderProviderTests: XCTestCase {
    func test___provides_same_recorder_for_same_configuration() throws {
        let specificProvider = SpecificMetricRecorderProviderImpl(
            mutableMetricRecorderProvider: FakeMutableMetricRecorderProvider()
        )
        let firstRecorder = try specificProvider.specificMetricRecorder(
            analyticsConfiguration: AnalyticsConfiguration()
        )
        let secondRecorder = try specificProvider.specificMetricRecorder(
            analyticsConfiguration: AnalyticsConfiguration()
        )
        
        assert {
            ObjectIdentifier(firstRecorder as AnyObject)
        } equals: {
            ObjectIdentifier(secondRecorder as AnyObject)
        }
    }
    
    func test___provides_different_recorders_for_different_configurations() throws {
        let specificProvider = SpecificMetricRecorderProviderImpl(
            mutableMetricRecorderProvider: FakeMutableMetricRecorderProvider()
        )
        let firstRecorder = try specificProvider.specificMetricRecorder(
            analyticsConfiguration: AnalyticsConfiguration()
        )
        let secondRecorder = try specificProvider.specificMetricRecorder(
            analyticsConfiguration: AnalyticsConfiguration(
                graphiteConfiguration: nil,
                statsdConfiguration: MetricConfiguration(socketAddress: SocketAddress(host: "example.com", port: 2003), metricPrefix: "prefix")
            )
        )
        
        XCTAssertNotEqual(
            ObjectIdentifier(firstRecorder as AnyObject),
            ObjectIdentifier(secondRecorder as AnyObject)
        )
    }
    
    func test___tear_down_happens_for_all_provided_recorders() throws {
        let mutableMetricRecorderProvider = FakeMutableMetricRecorderProvider()
        
        var providedFakeMutableMetricRecorders = [FakeMutableMetricRecorder]()
        mutableMetricRecorderProvider.generator = {
            let recorder = FakeMutableMetricRecorder()
            providedFakeMutableMetricRecorders.append(recorder)
            return recorder
        }
        
        let specificProvider = SpecificMetricRecorderProviderImpl(
            mutableMetricRecorderProvider: mutableMetricRecorderProvider
        )
        _ = try specificProvider.specificMetricRecorder(
            analyticsConfiguration: AnalyticsConfiguration()
        )
        _ = try specificProvider.specificMetricRecorder(
            analyticsConfiguration: AnalyticsConfiguration()
        )
        _ = try specificProvider.specificMetricRecorder(
            analyticsConfiguration: AnalyticsConfiguration(
                graphiteConfiguration: nil,
                statsdConfiguration: MetricConfiguration(socketAddress: SocketAddress(host: "host", port: 0), metricPrefix: "prefix")
            )
        )
        
        specificProvider.tearDown(timeout: 10)
        
        for providedRecorder in providedFakeMutableMetricRecorders {
            assertTrue { providedRecorder.tornDown }
        }
    }
}

class FakeMutableMetricRecorder: MutableMetricRecorder {
    func setGraphiteMetric(handler: GraphiteMetricHandler) throws {}
    func setStatsdMetric(handler: StatsdMetricHandler) throws {}
    
    var capturedGraphiteMetrics = [GraphiteMetric]()
    var capturedStatsdMetrics = [StatsdMetric]()
    
    func capture(_ metric: GraphiteMetric) {
        capturedGraphiteMetrics.append(metric)
    }
    
    func capture(_ metric: StatsdMetric) {
        capturedStatsdMetrics.append(metric)
    }
    
    var tornDown = false
    
    func tearDown(timeout: TimeInterval) {
        tornDown = true
    }
}

class FakeMutableMetricRecorderProvider: MutableMetricRecorderProvider {
    var generator: () -> MutableMetricRecorder = {
        FakeMutableMetricRecorder()
    }
    
    func metricRecorder() -> MutableMetricRecorder {
        generator()
    }
}
