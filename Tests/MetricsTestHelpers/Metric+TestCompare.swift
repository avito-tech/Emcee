import Graphite
import Metrics

public extension GraphiteMetric {
    func testCompare(_ other: GraphiteMetric) -> Bool {
        return self.components == other.components
            && self.value == other.value
    }
}
