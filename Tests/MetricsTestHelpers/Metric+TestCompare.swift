import Metrics

public extension Metric {
    func testCompare(_ other: Metric) -> Bool {
        return self.components == other.components
            && self.value == other.value
    }
}
