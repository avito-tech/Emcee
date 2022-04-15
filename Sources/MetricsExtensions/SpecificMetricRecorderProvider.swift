import AtomicModels
import Foundation
import MetricsRecording

public protocol SpecificMetricRecorderProvider {
    func specificMetricRecorder(
        analyticsConfiguration: AnalyticsConfiguration
    ) throws -> SpecificMetricRecorder
    
    func tearDown(timeout: TimeInterval)
}

public final class SpecificMetricRecorderProviderImpl: SpecificMetricRecorderProvider {
    private let cache = AtomicValue([AnalyticsConfiguration: SpecificMetricRecorder]())
    private let mutableMetricRecorderProvider: MutableMetricRecorderProvider
    
    public init(mutableMetricRecorderProvider: MutableMetricRecorderProvider) {
        self.mutableMetricRecorderProvider = mutableMetricRecorderProvider
    }
    
    public func specificMetricRecorder(
        analyticsConfiguration: AnalyticsConfiguration
    ) throws -> SpecificMetricRecorder {
        try cache.withExclusiveAccess {
            if let cachedInstance = $0[analyticsConfiguration] {
                return cachedInstance
            }
            
            let recorder = mutableMetricRecorderProvider.metricRecorder()
            try recorder.set(analyticsConfiguration: analyticsConfiguration)
            let instance = SpecificMetricRecorderWrapper(recorder)
            $0[analyticsConfiguration] = instance
            
            return instance
        }
    }
    
    public func tearDown(timeout: TimeInterval) {
        let queue = DispatchQueue(
            label: "SpecificMetricRecorderProviderImpl.tearDown",
            attributes: .concurrent,
            target: .global()
        )
        
        cache.withExclusiveAccess {
            for item in $0 {
                queue.async {
                    item.value.tearDown(timeout: timeout)
                }
            }
        }
        
        queue.sync(flags: .barrier) {}
    }
}

public final class NoOpSpecificMetricRecorderProvider: SpecificMetricRecorderProvider {
    private static let instance = SpecificMetricRecorderWrapper(
        MetricRecorderImpl(
            graphiteMetricHandler: NoOpMetricHandler(),
            statsdMetricHandler: NoOpMetricHandler()
        )
    )
    
    public init() {}
    
    public func specificMetricRecorder(
        analyticsConfiguration: AnalyticsConfiguration
    ) throws -> SpecificMetricRecorder {
        NoOpSpecificMetricRecorderProvider.instance
    }
    
    public func tearDown(timeout: TimeInterval) {}
}
