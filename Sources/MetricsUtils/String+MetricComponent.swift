import Foundation

public extension String {
    var suitableForMetric: String {
        return self
            .replacingOccurrences(of: ".", with: "_")
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "#", with: "_")
    }
}
