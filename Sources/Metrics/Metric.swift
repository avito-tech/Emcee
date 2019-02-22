import Foundation

open class Metric: CustomStringConvertible, Hashable {
    /// Components that form a fully qualified name of a metric.
    public let components: [String]
    
    /// Metric value.
    public let value: Double
    
    /// Timestamp when metric has been collected.
    public let timestamp: Date

    /// - Parameter fixedComponents: components that are fixed for this metric, and they should not change in the future
    /// - Parameter variableComponents: these components you can use as a variable parameters, and they can change.
    /// - Parameter value: The value for the parametrized metric.
    /// - Parameter timestamp: The timestamp when the metric has been captured.
    public init(
        fixedComponents: [String],
        variableComponents: [String],
        value: Double,
        timestamp: Date)
    {
        self.components = (fixedComponents + variableComponents).map { $0.suitableForMetric }
        self.value = value
        self.timestamp = timestamp
    }
    
    public var description: String {
        return "<\(type(of: self)) components=\(components), value=\(value), ts=\(timestamp)>"
    }

    public static func ==(left: Metric, right: Metric) -> Bool {
        return left.components == right.components
            && left.value == right.value
            && left.timestamp == right.timestamp
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(components)
        hasher.combine(value)
        hasher.combine(timestamp)
    }
}
