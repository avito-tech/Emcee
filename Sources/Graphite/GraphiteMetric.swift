import Foundation
import MetricsUtils

open class GraphiteMetric: CustomStringConvertible, Hashable {
    /// Components that form a fully qualified name of a metric.
    public let components: [String]
    
    /// Metric value.
    public let value: Double
    
    /// Timestamp when metric has been collected.
    public let timestamp: Date
    
    /// Common reserved field to be used in variable components.
    public static let reservedField = "reserved"

    /// - Parameter fixedComponents: Components that are fixed for this metric, and they must NOT change in the future.
    ///                              Consider introducing a new metric if you need to change this array.
    /// - Parameter variableComponents: Components to be used as variable parameters.
    ///                                 Consider introducing a new metric if you need to change the count of elements in this array.
    ///                                 **Count must NOT change!** Values may change.
    /// - Parameter value: The value for the parametrized metric.
    /// - Parameter timestamp: The timestamp when the metric has been captured.
    public init(
        fixedComponents: [StaticString],
        variableComponents: [String],
        value: Double,
        timestamp: Date)
    {
        self.components = (fixedComponents.map { $0.description } + variableComponents).map { $0.suitableForMetric }
        self.value = value
        self.timestamp = timestamp
    }
    
    public var description: String {
        return "<\(type(of: self)) components=\(components), value=\(value), ts=\(timestamp)>"
    }

    public static func ==(left: GraphiteMetric, right: GraphiteMetric) -> Bool {
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
