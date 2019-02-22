import Foundation

public extension String {
    public var suitableForMetric: String {
        return self
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: " ", with: "_")
    }
}
